#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>
#include <vector>
#include <Wire.h>
#include <LiquidCrystal_I2C.h>

// ---------- Configuração ----------
#include "secrets.h"

const char* WIFI_SSID     = WIFI_SSID_REAL;
const char* WIFI_SENHA    = WIFI_SENHA_REAL;
const char* URL_BASE      = URL_BASE_REAL;
const char* CHAVE_MAQUINA = CHAVE_MAQUINA_REAL;

// Pinos
const int PIN_LED     = 26;
const int PIN_SUCESSO = 25;
const int PIN_ERRO    = 27;
LiquidCrystal_I2C lcd(0x27, 20, 4);

unsigned long ultimaAnimacaoLCD = 0;
int pontosLCD = 0;

// Tempo "mockado" da medição: a cada CM_POR_PASSO centímetros, MS_POR_PASSO ms
const float CM_POR_PASSO = 10.0;
const unsigned long MS_POR_PASSO = 100;

// Tempos gerais
const unsigned long INTERVALO_CONSULTA_MS  = 2000;   // pergunta por trabalho (ocioso)
const unsigned long INTERVALO_BATIMENTO_MS = 8000;   // "estou vivo" durante o trabalho
const unsigned long INTERVALO_HEAP_MS      = 30000;  // monitor de memória (diagnóstico)
const unsigned long PISCA_MS    = 250;               // LED piscando
const unsigned long HOLD_MS     = 1000;              // segurar o botão de erro
const unsigned long DEBOUNCE_MS = 40;
const unsigned long REENVIO_MS  = 2000;

// ---------- Estado ----------
WiFiClientSecure seguro;
WiFiClient simples;

enum Estado { OCIOSO, MEDINDO, PRONTO };
Estado estado = OCIOSO;

std::vector<int> fioIds;
size_t indice = 0;
float metragemM = 0;
String materialAtual = "";

unsigned long ultimaConsulta = 0;
unsigned long ultimoContato = 0;
unsigned long ultimoHeap = 0;
unsigned long inicioEstado = 0;
unsigned long duracaoMedicaoMs = 0;
unsigned long ultimoPisca = 0;
bool ledLigado = false;
bool backendOk = false;

// botões
bool sucessoAntes = false;
bool erroAntes = false;
bool erroLongoTratado = false;
unsigned long erroInicio = 0;
unsigned long ultimaBorda = 0;
volatile int acaoPendente = 0;
volatile bool aceitandoBotoes = false;
volatile unsigned long inicioAceite = 0;

// ---------- Rede ----------
void conectarWifi() {
  mostrarLCD("Conectando ao Wi-Fi", "Aguarde...");
  Serial.printf("Conectando ao Wi-Fi '%s'", WIFI_SSID);
  WiFi.mode(WIFI_STA);
  WiFi.begin(WIFI_SSID, WIFI_SENHA);

  unsigned long inicio = millis();
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
    if (millis() - inicio > 20000) {
      Serial.println(" sem sucesso, tentando de novo");
      WiFi.disconnect();
      delay(1000);
      WiFi.begin(WIFI_SSID, WIFI_SENHA);
      inicio = millis();
    }
  }
  Serial.printf(" conectado! IP: %s\n", WiFi.localIP().toString().c_str());
}

bool iniciarRequisicao(HTTPClient& http, const String& url) {
  http.setTimeout(8000);
  http.setReuse(false);
  if (url.startsWith("https://")) return http.begin(seguro, url);
  return http.begin(simples, url);
}

void registrarFalha(HTTPClient& http, int codigo) {
  char msg[100] = "";
  int erroTls = seguro.lastError(msg, sizeof(msg));
  Serial.printf("Falha de conexao: %s (TLS %d: %s) | heap livre: %u, maior bloco: %u\n",
                http.errorToString(codigo).c_str(), erroTls, msg,
                ESP.getFreeHeap(), ESP.getMaxAllocHeap());
  http.end();
  seguro.stop(); // zera a conexão para a próxima tentativa começar limpa
}

// GET /maquina/trabalho
// true se recebeu um lote novo para trabalhar
bool consultarTrabalho(bool guardar) {
  HTTPClient http;
  String url = String(URL_BASE) + "/maquina/trabalho";

  if (!iniciarRequisicao(http, url)) {
    Serial.println("Nao foi possivel iniciar a requisicao");
    return false;
  }
  http.addHeader("x-maquina-chave", CHAVE_MAQUINA);

  int codigo = http.GET();
  ultimoContato = millis();

  if (codigo <= 0) {
    registrarFalha(http, codigo);
    return false;
  }

  String corpo = http.getString();
  http.end();

  if (codigo != 200) {
    Serial.printf("Backend respondeu %d: %s\n", codigo, corpo.c_str());
    return false;
  }

  if (!backendOk) {
    backendOk = true;
    Serial.println("Backend ok (200)");
  }

  if (!guardar) return false;

  JsonDocument doc;
  if (deserializeJson(doc, corpo)) {
    Serial.println("JSON invalido");
    return false;
  }

  JsonVariant trabalho = doc["trabalho"];
  if (trabalho.isNull()) return false;

  fioIds.clear();
  for (JsonObject fio : trabalho["fios"].as<JsonArray>()) {
    fioIds.push_back(fio["id_fio"].as<int>());
  }
  if (fioIds.empty()) return false;

  metragemM = trabalho["metragem"].as<float>();
  materialAtual = trabalho["material"].as<String>();
  indice = 0;

  mostrarLCD("Lote recebido!", String(fioIds.size()) + " fios");
  delay(1500);

  Serial.println("---------------------------");
  Serial.printf("Trabalho recebido (%s)\n", trabalho["tipo"].as<const char*>());
  Serial.printf("Execucao: %d\n", trabalho["id_execucao"].as<int>());
  Serial.printf("Metragem: %.2f m | Material: %s\n", metragemM, materialAtual.c_str());
  Serial.printf("Fios pendentes: %d\n", (int)fioIds.size());
  return true;
}

// POST /maquina/fios/:id/resultado
// 1 = ok, 0 = tentar de novo, -1 = erro definitivo
int enviarResultado(int idFio, const char* status, const char* codigoErro) {
  HTTPClient http;
  String url = String(URL_BASE) + "/maquina/fios/" + idFio + "/resultado";
  if (!iniciarRequisicao(http, url)) return 0;

  http.addHeader("x-maquina-chave", CHAVE_MAQUINA);
  http.addHeader("Content-Type", "application/json");

  JsonDocument corpoJson;
  corpoJson["status"] = status;
  if (codigoErro != nullptr) corpoJson["codigo_erro"] = codigoErro;
  String corpo;
  serializeJson(corpoJson, corpo);

  int codigo = http.POST(corpo);
  ultimoContato = millis();

  if (codigo <= 0) {
    registrarFalha(http, codigo);
    return 0;
  }

  String resposta = http.getString();
  http.end();

  if (codigo == 200) return 1;
  if (codigo >= 500) {
    Serial.printf("Servidor respondeu %d, vou tentar de novo\n", codigo);
    return 0;
  }
  Serial.printf("Backend respondeu %d: %s\n", codigo, resposta.c_str());
  return -1;
}

// ---------- LED e botões ----------
void ledAtualizar(bool ligar) {
  ledLigado = ligar;
  digitalWrite(PIN_LED, ligar ? HIGH : LOW);
}

// 0 = nada, 1 = sucesso, 2 = erro (toque), 3 = erro (segurar)
int lerBotoes() {
  unsigned long agora = millis();
  bool sucesso = (digitalRead(PIN_SUCESSO) == LOW);
  bool erro = (digitalRead(PIN_ERRO) == LOW);
  int acao = 0;

  if (sucesso && !sucessoAntes && agora - ultimaBorda > DEBOUNCE_MS) {
    acao = 1;
    ultimaBorda = agora;
  }
  sucessoAntes = sucesso;

  if (erro && !erroAntes) {
    erroInicio = agora;
    erroLongoTratado = false;
  }
  if (erro && !erroLongoTratado && agora - erroInicio >= HOLD_MS) {
    erroLongoTratado = true;
    acao = 3;
  }
  if (!erro && erroAntes) {
    if (!erroLongoTratado && agora - erroInicio >= DEBOUNCE_MS) acao = 2;
  }
  erroAntes = erro;

  return acao;
}

void tarefaBotoes(void* param) {
  for (;;) {
    int acao = lerBotoes();
    if (acao != 0 && aceitandoBotoes && acaoPendente == 0) {
      // ignora um toque que começou antes de o fio ficar pronto
      if (acao == 1 || erroInicio >= inicioAceite) acaoPendente = acao;
    }
    vTaskDelay(pdMS_TO_TICKS(5));
  }
}

// ---------- Fluxo do fio ----------
void iniciarFio() {
  int passos = (int)ceil((metragemM * 100.0) / CM_POR_PASSO);
  duracaoMedicaoMs = (unsigned long)passos * MS_POR_PASSO;
  Serial.printf("Fio %d (%d de %d): medindo por %lu ms...\n",
                fioIds[indice], (int)indice + 1, (int)fioIds.size(), duracaoMedicaoMs);
  mostrarLCD("Medindo fio " + String(indice + 1) + "/" + String(fioIds.size()),
          String(metragemM, 2) + " metros");
  estado = MEDINDO;
  inicioEstado = millis();
  ultimoPisca = millis();
  ledAtualizar(true);
}

void finalizarFio(const char* status, const char* codigoErro) {
  int idFio = fioIds[indice];
  int r = enviarResultado(idFio, status, codigoErro);
  while (r == 0) {
    mostrarLCD("Sem conexao", "Reenviando...");
    delay(REENVIO_MS);
    if (WiFi.status() != WL_CONNECTED) conectarWifi();
    r = enviarResultado(idFio, status, codigoErro);
  }
  if (r == 1) {
    Serial.printf("Resultado do fio %d enviado: %s\n", idFio,
                  codigoErro ? codigoErro : "SUCESSO");
  }

  if (codigoErro == nullptr) {
    mostrarLCD("Fio concluido!", "Resultado: OK");
  }
  else if (String(codigoErro) == "FALHA_MEDICAO") {
    mostrarLCD("Falha medicao", "Fio rejeitado");
  }
  else if (String(codigoErro) == "FIO_TRAVOU") {
    mostrarLCD("Fio travou!", "Fio rejeitado");
  }

  delay(1500);

  indice++;
  if (indice < fioIds.size()) {
    iniciarFio();
  } else {
    Serial.println("Fim dos fios deste lote. Voltando a procurar trabalho.");

    mostrarLCD("Todos os cortes", "foram finalizados!");
    delay(2000);
    mostrarLCD("Maquina pronta", "Aguardando corte");

    ledAtualizar(false);
    estado = OCIOSO;
    ultimaConsulta = 0;
  }
}

// ---------- Display ----------
void mostrarLCD(String linha1, String linha2) {
  lcd.clear();

  lcd.setCursor(0, 0);
  lcd.print("====================");

  lcd.setCursor(0, 1);
  lcd.print(linha1.substring(0, 20));

  lcd.setCursor(0, 2);
  lcd.print(linha2.substring(0, 20));

  lcd.setCursor(0, 3);
  lcd.print("====================");
}

// volta para a tela do estado atual (caso tenha reconectado o wifi)
void restaurarTela() {
  if (estado == OCIOSO) {
    mostrarLCD("Maquina pronta", "Aguardando corte");
  } else if (estado == PRONTO) {
    mostrarLCD("Fio " + String(indice + 1) + " pronto!", "Verde=ok Verm=erro");
  } else {
    mostrarLCD("Medindo fio " + String(indice + 1) + "/" + String(fioIds.size()),
               String(metragemM, 2) + " metros");
  }
}

void animarLCD() {
  if (millis() - ultimaAnimacaoLCD >= 500) {
    ultimaAnimacaoLCD = millis();

    pontosLCD++;

    if (pontosLCD > 10) {
      pontosLCD = 0;
    }

    lcd.setCursor(0, 3);
    lcd.print("                    ");
    lcd.setCursor(0, 3);
    for (int i = 0; i < pontosLCD; i++) {
      lcd.print(".");
    }
  }
}

// ---------- Arduino ----------
void setup() {
  Serial.begin(115200);

  Wire.begin(32, 33);

  lcd.init();
  lcd.backlight();

  mostrarLCD("Maquina ligada", "Inicializando...");
  
  delay(500);
  Serial.println("Maquina de cortes");

  pinMode(PIN_LED, OUTPUT);
  pinMode(PIN_SUCESSO, INPUT_PULLUP);
  pinMode(PIN_ERRO, INPUT_PULLUP);
  ledAtualizar(false);

  sucessoAntes = (digitalRead(PIN_SUCESSO) == LOW);
  erroAntes = (digitalRead(PIN_ERRO) == LOW);
  erroLongoTratado = erroAntes;
  xTaskCreatePinnedToCore(tarefaBotoes, "botoes", 2048, NULL, 1, NULL, 0);

  seguro.setInsecure(); // só para desenvolvimento (não valida o certificado)
  conectarWifi();
  mostrarLCD("Maquina pronta", "Aguardando corte");
}

void loop() {
  if (WiFi.status() != WL_CONNECTED) {
    conectarWifi();
    restaurarTela();
  }

  unsigned long agora = millis();

  // diagnóstico
  if (agora - ultimoHeap >= INTERVALO_HEAP_MS) {
    ultimoHeap = agora;
    Serial.printf("[heap livre: %u | maior bloco: %u]\n",
                  ESP.getFreeHeap(), ESP.getMaxAllocHeap());
  }

  switch (estado) {
    case OCIOSO:
      if (agora - ultimaConsulta >= INTERVALO_CONSULTA_MS) {
        ultimaConsulta = agora;
        if (consultarTrabalho(true)) iniciarFio();
      }
      break;

    case MEDINDO:
      if (agora - ultimoPisca >= PISCA_MS) {
        ultimoPisca = agora;
        ledAtualizar(!ledLigado);
      }
      if (agora - inicioEstado >= duracaoMedicaoMs) {
        ledAtualizar(true);
        estado = PRONTO;
        acaoPendente = 0;
        inicioAceite = millis();
        aceitandoBotoes = true;
        Serial.println("Fio pronto. Verde = sucesso | Vermelho: toque = falha na medicao, segurar = fio travou");
        mostrarLCD("Fio " + String(indice + 1) + " pronto!", "Verde=ok Verm=erro");
      }
      break;

    case PRONTO: {
      int acao = acaoPendente;
      if (acao != 0) {
        acaoPendente = 0;
        aceitandoBotoes = false;
        ledAtualizar(false);
        Serial.println("Botao registrado, enviando...");
        if (acao == 1) finalizarFio("C", nullptr);
        else if (acao == 2) finalizarFio("E", "FALHA_MEDICAO");
        else if (acao == 3) finalizarFio("E", "FIO_TRAVOU");
      }
      break;
    }
  }

  if (estado == MEDINDO) {
    animarLCD();
  }

  // "estou vivo" enquanto trabalha
  if (estado != OCIOSO && millis() - ultimoContato >= INTERVALO_BATIMENTO_MS) {
    consultarTrabalho(false);
  }
}