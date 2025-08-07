
# 📊 Documentação das Métricas - Projeto Flask Light Game

Este projeto expõe métricas Prometheus via o endpoint `/metrics`, utilizando a biblioteca oficial [`prometheus_client`](https://github.com/prometheus/client_python).

Essas métricas permitem monitoramento em tempo real da aplicação, atividades dos jogadores e comportamento do jogo.

---

## 📍 Endpoint de Métricas

- **URL**: `/metrics`
- **Método**: `GET`
- **Conteúdo**: Texto no formato Prometheus (MIME type: `text/plain; version=0.0.4`)

---

## 🔧 Métricas Customizadas

### 1. 🔁 `toggle_light_total`

- **Tipo**: `Counter`
- **Nome**: `toggle_light_total`
- **Descrição**: Conta o número total de vezes que a luz foi alternada (ligada ou desligada).
- **Exemplo**:

```text
toggle_light_total 42
```

---

### 2. 🕒 `light_duration_seconds`

- **Tipo**: `Histogram`
- **Nome**: `light_duration_seconds`
- **Descrição**: Mede quanto tempo (em segundos) a luz ficou acesa antes de ser desligada.
- **Exemplo**:

```text
light_duration_seconds_bucket{le="0.5"} 3
light_duration_seconds_bucket{le="1.0"} 8
light_duration_seconds_count 15
light_duration_seconds_sum 22.47
```

---

### 3. 👥 `players_connected`

- **Tipo**: `Gauge`
- **Nome**: `players_connected`
- **Descrição**: Número atual de jogadores conectados via WebSocket.
- **Exemplo**:

```text
players_connected 5
```

---

## 🧩 Integração no Código

| Métrica                 | Arquivo            | Localização                                              |
|-------------------------|--------------------|-----------------------------------------------------------|
| `toggle_light_total`    | `socket_events.py` | Dentro do handler `@socketio.on("toggle_light")`         |
| `light_duration_seconds`| `game.py`          | Dentro do método `toggle_light()` ao desligar a luz      |
| `players_connected`     | `socket_events.py` | Handlers `connect` e `disconnect`                        |

---

## 📦 Requisitos

Adicione ao seu `requirements.txt`:

```
prometheus_client==0.20.0
```

---

## 🔄 Exemplo de Fluxo Prometheus

Para coletar essas métricas, adicione a seguinte configuração no seu `prometheus.yml`:

```yaml
scrape_configs:
  - job_name: "light_game"
    static_configs:
      - targets: ["localhost:5000"]
```

> **Nota:** Ajuste a porta e host conforme necessário no seu ambiente (ex: Docker Compose).

---

## 🛠️ Próximos Passos

- Adicionar visualizações no Grafana
- Criar alertas baseados nas métricas
- Integrar com Docker Compose para observabilidade completa

---
