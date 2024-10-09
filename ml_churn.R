library(dplyr)
library(h2o)
library(highcharter)
library(readr)
library(writexl)

# Aumentar o tempo limite para 300 segundos (5 minutos)
#  se tiver timeout pra instalar o h2o.
# options(timeout = 300)
# install.packages("h2o")

# Preparando objetos
ml <- list()

# Iniciar o cluster h2o
h2o.init()

# Lendo os dados
ml$data$raw <- read_csv(
  "https://raw.githubusercontent.com/wrprates/open-data/master/telco_customer_churn.csv"
) |>
  mutate(across(where(is.character), as.factor))

# Definindo variáveis
ml$vars$y <- "Churn"
ml$vars$discard <- "customerID"
ml$vars$x <- setdiff(names(ml$data$raw), c(ml$vars$y, ml$vars$discard))

# Configurar h2o
ml$data$h2o <- as.h2o(ml$data$raw)
ml$data$splits <- h2o.splitFrame(ml$data$h2o, ratios = 0.7)
names(ml$data$splits) <- c("train", "test")

# Executar o modelo - GBM
ml$model <- h2o.gbm(x = ml$vars$x, y = ml$vars$y, training_frame = ml$data$splits$train)
ml$predictions <- h2o.predict(ml$model, ml$data$splits$test)
h2o.performance(ml$model, ml$data$splits$test)

h2o.r2(ml$model)

# Adicionar as previsões aos dados originais
ml$data$predictions <- ml$data$splits$test |>
  as_tibble() |>
  bind_cols(
    as_tibble(ml$predictions) |> 
      select(Predict = predict, PredictProbability = Yes) |>
      mutate(PredictProbability = round(100*PredictProbability, 2))
  ) |>
  # 11 não é um "número mágico", é apenas inverter a ordem dos decís.
  mutate(RiskGroup = as.factor(11 - ntile(PredictProbability, 10))) |>
  select(customerID, Churn, Predict, PredictProbability, RiskGroup, dplyr::everything()) |>
  arrange(desc(PredictProbability))

# Exportar para Excel
write_xlsx(ml$data$predictions, "predictions_r.xlsx")
