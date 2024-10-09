library(dplyr)
library(h2o)
library(highcharter)
library(readr)
library(writexl)

# Preparing objects
ml <- list()

# Start h2o cluster
h2o::h2o.init()

# Reading the data
ml$data$raw <- readr::read_csv(
  "https://raw.githubusercontent.com/wrprates/open-data/master/telco_customer_churn.csv"
) |>
  dplyr::mutate(across(where(is.character), as.factor))

# Defining variables
ml$vars$y <- "Churn"
ml$vars$discard <- "customerID"
ml$vars$x <- setdiff(names(ml$data$raw), c(ml$vars$y, ml$vars$discard))

# Setup h2o
ml$data$h2o <- h2o::as.h2o(ml$data$raw)
ml$data$splits <- h2o::h2o.splitFrame(ml$data$h2o, ratios = 0.7)
names(ml$data$splits) <- c("train", "test")

# Running the model - GBM
ml$model <- h2o::h2o.gbm(x = ml$vars$x, y = ml$vars$y, training_frame = ml$data$splits$train)
ml$predictions <- h2o::h2o.predict(ml$model, ml$data$splits$test)
h2o::h2o.performance(ml$model, ml$data$splits$test)

h2o.r2(ml$model)

ml$data$predictions <- ml$data$splits$test |>
  tibble::as_tibble() |>
  dplyr::bind_cols(
    dplyr::as_tibble(ml$predictions) |> 
      dplyr::select(Predict = predict, PredictProbability = Yes) |>
      dplyr::mutate(PredictProbability = round(100*PredictProbability, 2))
  ) |>
  # 11 is not a magic number, it is inverting the order of the deciles
  dplyr::mutate(RiskGroup = as.factor(11 - dplyr::ntile(PredictProbability, 10))) |>
  dplyr::select(customerID, Churn, Predict, PredictProbability, RiskGroup, dplyr::everything()) |>
  dplyr::arrange(dplyr::desc(PredictProbability))

# Exportar para Excel
writexl::write_xlsx(ml$data$predictions, "predictions.xlsx")
