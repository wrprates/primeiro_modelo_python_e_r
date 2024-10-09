# Projeto de Previsão de Churn de Clientes

## Objetivo
O objetivo deste projeto é gerar uma nova coluna nos dados que traz a probabilidade de cada cliente ser churn (cancelar o serviço) ou não.

## Scripts
- `ml_churn.py`: Script em Python que utiliza o modelo Gradient Boosting Regressor para prever o churn.
- `ml_churn.R`: Script em R que utiliza o modelo GBM da biblioteca H2O para prever o churn.

## Execução
Para rodar os scripts sem precisar instalar nada, recomenda-se:
- **R**: Utilizar o [Posit Cloud](https://posit.cloud) para executar o script em R.
- **Python**: Utilizar o [Google Colab](https://colab.research.google.com) para executar o script em Python.

## Exportação
Os resultados das previsões são exportados para arquivos Excel (`predictions_python.xlsx` para Python e `predictions_r.xlsx` para R).
