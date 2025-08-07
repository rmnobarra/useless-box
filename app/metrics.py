from prometheus_client import Counter, Histogram, Gauge

# Total de cliques no botão de alternar luz
toggle_light_counter = Counter(
    "toggle_light_total",
    "Número total de vezes que a luz foi alternada"
)

# Duração da luz acesa
light_duration_histogram = Histogram(
    "light_duration_seconds",
    "Duração em segundos da luz acesa"
)

# Número de jogadores conectados
players_connected_gauge = Gauge(
    "players_connected",
    "Número atual de jogadores conectados"
)
