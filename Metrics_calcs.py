import psycopg2
import pymssql
import pandas as pd
import time
from tqdm import tqdm
import matplotlib.pyplot as plt
import datetime
from datetime import date
import numpy as np

def model(df_data_gen, df_gen, date_of_campaign, aggregation):
    
    
    metrics_list = []
    for test in range(2):
        for period in ['before', 'after']:

            df = df_gen[df_gen['test_group'] == test]
            df_data = df_data_gen[df_data_gen['test_group'] == test]
            
            if period == 'before':
                df = df[df['Date_Key'] < date_of_campaign] 
            else:
                df = df[df['Date_Key'] >= date_of_campaign]

            metrics_value = metrics(df_data, df, aggregation)
            metrics_value.append(test)
            metrics_value.append(period)

            metrics_list.append(metrics_value)


    names = ['Population',
     'Number_Rides',
     'Revenue',
     'Gross_Profit',
     'Gp_per_ride',
     'Average_Check',
     'Average_Duration',
     'Rides_per_user',
     'Sales_per_user',
     'GP_per_user',
     'Weekly_ARPU',
     'Monthly_ARPU',
     'WAU',
     'MAU',
     'Test',
     'Period']

    data_results = pd.DataFrame(metrics_list, columns = names)

    columns = ['Test',
     'Period',
     'Population',
     'Number_Rides',
     'Revenue',
     'Gross_Profit',
     'Gp_per_ride',
     'Average_Check',
     'Average_Duration',
     'Rides_per_user',
     'Sales_per_user',
     'GP_per_user',
     'Weekly_ARPU',
     'Monthly_ARPU',
     'WAU',
     'MAU']

    data_results = data_results[columns]
    return data_results


def metrics(df_data, df, aggregation):
    population = df_data.shape[0]
    number_rides = int(np.mean(df.groupby('Date_Key')['Order_GK'].count())*aggregation)
    revenue = int(np.mean(df.groupby('Date_Key')['Customer_Total_Cost_Inc_Vat'].sum())*aggregation)
    gross_profit = int(np.mean(df.groupby('Date_Key')['margin_sum'].sum())*aggregation)

    gp_per_ride = int(gross_profit/number_rides)
    
    average_check = int(revenue/number_rides)
    average_duration = int(df['M_Ride_Duration'].sum()/df['M_Ride_Duration'].count())

    rides_per_user = number_rides/population
    revenue_per_user = int(revenue/population)
    gp_per_user = int(gross_profit/population)
    weekly_ARPU = int(np.mean(df.groupby('Week_Key')['Customer_Total_Cost_Inc_Vat'].sum()/population))
    monthly_ARPU = int(np.mean(df.groupby('Month_Key')['Customer_Total_Cost_Inc_Vat'].sum()/population))
    
    
    wau_list = []
    for week in df['Week_Key'].unique():
        df_week = df[df['Week_Key'] == week]
        wau_list.append(len(df_week['User_GK'].unique()))

    WAU = int(np.mean(wau_list)/population*1000)

    MAU_list = []
    for month in df['Month_Key'].unique():
        df_month = df[df['Month_Key'] == month]
        MAU_list.append(len(df_month['User_GK'].unique()))

    MAU = int(np.mean(MAU_list)/population*1000)
    
    metrics = [population,number_rides,revenue,gross_profit,gp_per_ride,average_check,average_duration,rides_per_user,revenue_per_user,gp_per_user,weekly_ARPU,monthly_ARPU,WAU,MAU]
    return metrics
