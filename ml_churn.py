import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.ensemble import GradientBoostingRegressor
from sklearn.metrics import r2_score
import numpy as np
import openpyxl
from sklearn.preprocessing import LabelEncoder

# Lendo os dados
url = "https://raw.githubusercontent.com/wrprates/open-data/master/telco_customer_churn.csv"
raw_data = pd.read_csv(url)

# Convertendo colunas de texto para fator (categorical no pandas)
raw_data = raw_data.apply(lambda col: col.astype('category') if col.dtype == 'object' else col)

# Definindo variáveis
y = "Churn"
discard = "customerID"
x = [col for col in raw_data.columns if col not in [y, discard]]

# Encode Target Variable
label_encoder = LabelEncoder()
raw_data[y] = label_encoder.fit_transform(raw_data[y])  # Encode 'Yes'/'No' to 1/0

# Transformando categorias em dummies (necessário para scikit-learn)
data_dummies = pd.get_dummies(raw_data[x])

# Separando os dados em treino e teste
X_train, X_test, y_train, y_test = train_test_split(data_dummies, raw_data[y], test_size=0.3, random_state=42)

# Treinando o modelo - Gradient Boosting Regressor
gbm_model = GradientBoostingRegressor()
gbm_model.fit(X_train, y_train)

# Fazendo previsões
predictions = gbm_model.predict(X_test)

# Avaliando o modelo
r2 = r2_score(y_test, predictions)

# Criando um DataFrame para armazenar as previsões e o grupo de risco
test_df = raw_data.loc[X_test.index].copy()  # Recuperando linhas do conjunto de teste original
test_df['Predict'] = predictions

# Criando a coluna 'RiskGroup' (decis invertidos)
test_df['RiskGroup'] = pd.qcut(test_df['Predict'], 10, labels=False, duplicates='drop')
test_df['RiskGroup'] = 11 - test_df['RiskGroup']  # Invertendo a ordem

# Reorganizando colunas
output_df = test_df[[discard, 'Churn', 'Predict', 'RiskGroup'] + [col for col in test_df.columns if col not in [discard, 'Churn', 'Predict', 'PredictProbability', 'RiskGroup']]]

# Exportando para Excel
output_df.to_excel('predictions_python.xlsx', index=False)
