# 2ren churn analytics

rm(list = ls())  # reset environment

#-----install libraries----
library(tidyverse)
library(janitor)
library(randomForest)
library(caret)
library(car)

#===============step 1: data overview=========

#---------load data + source info---------
# data source: kaggle "ecommerce customer churn analysis and prediction" by ankit verma
# file used: e-commerce-dataset.csv
store <- read.csv("e-commerce-dataset.csv")
store <- store %>% clean_names()

#---------basic structure---------
dim(store)      # 5630 rows, 20 columns
glimpse(store)  # variable names and types

#---------churn distribution---------
table(store$churn)
prop.table(table(store$churn))
# churn is imbalanced at about 16 to 17 percent

#---------missing value profile---------
missing_pct <- colSums(is.na(store)) / nrow(store) * 100
missing_pct
# several behavioral variables have about 4.5–5.5% missing
# imputation is needed but manageable

#---------quick summaries for key numeric variables---------
store %>%
  select(
    tenure,
    order_count,
    day_since_last_order,
    hour_spend_on_app,
    order_amount_hike_fromlast_year,
    coupon_used,
    cashback_amount
  ) %>%
  summary()
# this helps confirm ranges and spot extreme values

#===============step 2: data preparation=========

#---------impute missing numeric values---------
colSums(is.na(store))

store_imputed <- store %>%
  mutate(
    tenure = replace(tenure, is.na(tenure), median(tenure, na.rm = TRUE)),
    warehouse_to_home = replace(warehouse_to_home, is.na(warehouse_to_home), median(warehouse_to_home, na.rm = TRUE)),
    hour_spend_on_app = replace(hour_spend_on_app, is.na(hour_spend_on_app), median(hour_spend_on_app, na.rm = TRUE)),
    order_amount_hike_fromlast_year = replace(order_amount_hike_fromlast_year, is.na(order_amount_hike_fromlast_year), median(order_amount_hike_fromlast_year, na.rm = TRUE)),
    coupon_used = replace(coupon_used, is.na(coupon_used), median(coupon_used, na.rm = TRUE)),
    order_count = replace(order_count, is.na(order_count), median(order_count, na.rm = TRUE)),
    day_since_last_order = replace(day_since_last_order, is.na(day_since_last_order), median(day_since_last_order, na.rm = TRUE)),
    cashback_amount = replace(cashback_amount, is.na(cashback_amount), median(cashback_amount, na.rm = TRUE))
  )
# median imputation keeps rows and limits the impact of extreme values

colSums(is.na(store_imputed))  # no missing values remain

#---------check for outliers (1st and 99th percentiles)---------
oc_q   <- quantile(store_imputed$order_count, c(0.01, 0.99), na.rm = TRUE)
dslo_q <- quantile(store_imputed$day_since_last_order, c(0.01, 0.99), na.rm = TRUE)
cu_q   <- quantile(store_imputed$coupon_used, c(0.01, 0.99), na.rm = TRUE)
cb_q   <- quantile(store_imputed$cashback_amount, c(0.01, 0.99), na.rm = TRUE)
hike_q <- quantile(store_imputed$order_amount_hike_fromlast_year, c(0.01, 0.99), na.rm = TRUE)

# extreme values exist but are limited in number
sum(store_imputed$order_count < oc_q[1] | store_imputed$order_count > oc_q[2])
sum(store_imputed$day_since_last_order < dslo_q[1] | store_imputed$day_since_last_order > dslo_q[2])
sum(store_imputed$coupon_used < cu_q[1] | store_imputed$coupon_used > cu_q[2])
sum(store_imputed$cashback_amount < cb_q[1] | store_imputed$cashback_amount > cb_q[2])
sum(store_imputed$order_amount_hike_fromlast_year < hike_q[1] | store_imputed$order_amount_hike_fromlast_year > hike_q[2])

#---------simple outlier handling (cap at 1st and 99th percentiles)---------
store_imputed <- store_imputed %>%
  mutate(
    order_count = pmin(pmax(order_count, oc_q[1]), oc_q[2]),
    day_since_last_order = pmin(pmax(day_since_last_order, dslo_q[1]), dslo_q[2]),
    coupon_used = pmin(pmax(coupon_used, cu_q[1]), cu_q[2]),
    cashback_amount = pmin(pmax(cashback_amount, cb_q[1]), cb_q[2]),
    order_amount_hike_fromlast_year = pmin(pmax(order_amount_hike_fromlast_year, hike_q[1]), hike_q[2])
  )
# capping reduces distortion without dropping customers

#---------type conversions---------
store_imputed <- store_imputed %>%
  mutate(
    churn = as.factor(churn),
    customer_id = as.factor(customer_id)
  ) %>%
  mutate(across(where(is.character), as.factor))

str(store_imputed)

#---------feature engineering (churn-related signals)---------
store_imputed <- store_imputed %>%
  mutate(
    freq_per_month = order_count / (tenure + 1),
    tenure_bucket = case_when(
      tenure < 3 ~ "new",
      tenure >= 3 & tenure <= 12 ~ "medium",
      tenure > 12 ~ "long"
    ),
    recency_bucket = case_when(
      day_since_last_order <= 3 ~ "recent",
      day_since_last_order > 3 & day_since_last_order <= 14 ~ "warm",
      day_since_last_order > 14 ~ "cold"
    ),
    high_app_user = ifelse(hour_spend_on_app >= 3, 1, 0),
    approx_clv = order_count * 50 + cashback_amount
  ) %>%
  mutate(
    tenure_bucket = as.factor(tenure_bucket),
    recency_bucket = as.factor(recency_bucket),
    high_app_user = as.factor(high_app_user)
  )

store_imputed <- store_imputed %>%
  mutate(
    recency_score = 1 / (day_since_last_order + 1),
    frequency_score = order_count / max(order_count),
    monetary_score = approx_clv / max(approx_clv),
    rfm_score = recency_score + frequency_score + monetary_score,
    engagement_intensity = scale(hour_spend_on_app + coupon_used + number_of_device_registered)[, 1],
    loyal_customer = ifelse(tenure > 12, 1, 0)
  ) %>%
  mutate(loyal_customer = as.factor(loyal_customer))
# these features turn behavior into recency, frequency, value, and engagement signals

summary(store_imputed$rfm_score)
summary(store_imputed$engagement_intensity)
table(store_imputed$tenure_bucket)
table(store_imputed$recency_bucket)
table(store_imputed$loyal_customer)

#===============step 3: modeling and evaluation================

#---------3.1 train / test split (classification setup)---------
set.seed(123)  # reproducible results

index <- sample(1:nrow(store_imputed), size = 0.7 * nrow(store_imputed))
train <- store_imputed[index, ]
test  <- store_imputed[-index, ]

prop.table(table(train$churn))
prop.table(table(test$churn))
# churn balance is consistent across train and test

# remove id column before modeling
train_model <- train %>% select(-customer_id)
test_model  <- test  %>% select(-customer_id)

#---------3.2 logistic regression (baseline model)---------
logit_model <- glm(churn ~ ., data = train_model, family = binomial())
summary(logit_model)
# logistic regression is helpful for understanding churn drivers

logit_prob <- predict(logit_model, newdata = test_model, type = "response")
logit_pred <- ifelse(logit_prob > 0.5, 1, 0)

logit_cm <- table(predicted = logit_pred, actual = test_model$churn)
logit_cm

logit_cm2 <- confusionMatrix(
  factor(logit_pred, levels = c(0, 1)),
  test_model$churn,
  positive = "1"
)
logit_cm2

logit_accuracy <- mean(logit_pred == test_model$churn)
logit_accuracy
# accuracy is about 0.89
# this means the model gets about 89 out of 100 predictions right

# precision is about 0.70
# when the model says a customer will churn, it is correct about 70 percent of the time

# recall is about 0.58
# this means the model finds about 58 percent of all real churners
# some churners are missed

# f1 score is about 0.63
# this is a balance between precision and recall

# takeaway:
# logistic regression does an okay job
# it is useful for explaining churn drivers, but it misses more churners

#---------3.3 random forest (primary model)---------
set.seed(123)

rf_model <- randomForest(
  churn ~ .,
  data = train_model,
  ntree = 300,
  importance = TRUE
)
rf_model
# random forest usually catches more churners and makes fewer mistakes

importance(rf_model)
varImpPlot(rf_model)

rf_prob <- predict(rf_model, newdata = test_model, type = "prob")[, 2]
rf_pred <- ifelse(rf_prob > 0.5, 1, 0)

rf_cm <- table(predicted = rf_pred, actual = test_model$churn)
rf_cm

rf_cm2 <- confusionMatrix(
  factor(rf_pred, levels = c(0, 1)),
  test_model$churn,
  positive = "1"
)
rf_cm2

rf_accuracy <- mean(rf_pred == test_model$churn)
rf_accuracy
# accuracy is about 0.96
# this means the model gets about 96 out of 100 predictions right

# precision is about 0.92
# when the model flags a customer as churn, it is correct most of the time

# recall is about 0.85
# this means the model finds about 85 percent of all real churners
# far fewer churners are missed compared to logistic regression

# f1 score is about 0.88
# this is a strong balance between precision and recall

# takeaway:
# random forest performs better across all metrics
# this is the better model to use in practice

#---------3.4 business-calibrated evaluation (roi)---------
monthly_value        <- 50
months_lost_if_churn <- 12
value_per_churn      <- monthly_value * months_lost_if_churn

coupon_cost <- 10

logit_TP <- as.numeric(logit_cm["1", "1"])
logit_FP <- as.numeric(logit_cm["1", "0"])
rf_TP    <- as.numeric(rf_cm["1", "1"])
rf_FP    <- as.numeric(rf_cm["1", "0"])

logit_value_saved <- logit_TP * value_per_churn
rf_value_saved    <- rf_TP    * value_per_churn

logit_campaign_cost <- (logit_TP + logit_FP) * coupon_cost
rf_campaign_cost    <- (rf_TP + rf_FP) * coupon_cost

logit_net_roi <- logit_value_saved - logit_campaign_cost
rf_net_roi    <- rf_value_saved - rf_campaign_cost

business_eval <- data.frame(
  model         = c("logistic regression", "random forest"),
  tp            = c(logit_TP, rf_TP),
  fp            = c(logit_FP, rf_FP),
  value_saved   = c(logit_value_saved, rf_value_saved),
  campaign_cost = c(logit_campaign_cost, rf_campaign_cost),
  net_roi       = c(logit_net_roi, rf_net_roi)
)
business_eval
# this connects model performance to business value using simple assumptions

#---------3.5 final modeling summary---------
# logistic regression is easier to explain
# random forest performs better and is more useful for retention targeting

#===============step 4: clustering (k-means customer segments)================

#---------4.1 select features for clustering---------
cluster_vars <- store_imputed %>%
  select(
    tenure,
    order_count,
    day_since_last_order,
    cashback_amount,
    approx_clv,
    freq_per_month,
    rfm_score,
    engagement_intensity
  )

# make sure features are on the same scale
cluster_scaled <- scale(cluster_vars)

#---------4.2 run k-means clustering---------
set.seed(123)
k <- 3  # simple segmentation for interpretation

kmeans_model <- kmeans(
  x = cluster_scaled,
  centers = k,
  nstart = 25
)

kmeans_model$size
# cluster sizes:
# cluster 1 has about 1592 customers
# cluster 2 has about 3264 customers
# cluster 3 has about 774 customers
# this shows cluster 2 is the largest group

kmeans_model$withinss
# within-cluster values show how similar customers are inside each cluster
# lower numbers mean customers in that cluster behave more similarly

kmeans_model$betweenss
# betweenss measures how separated the clusters are from each other
# a higher value means the clusters are more distinct

# attach clusters back to the main data
store_imputed <- store_imputed %>%
  mutate(cluster_k3 = factor(kmeans_model$cluster))

#---------4.3 cluster profiles---------
cluster_profile <- store_imputed %>%
  group_by(cluster_k3) %>%
  summarise(
    n_customers        = n(),
    avg_tenure         = mean(tenure),
    avg_order_count    = mean(order_count),
    avg_recency_days   = mean(day_since_last_order),
    avg_cashback       = mean(cashback_amount),
    avg_approx_clv     = mean(approx_clv),
    avg_freq_per_month = mean(freq_per_month),
    avg_rfm_score      = mean(rfm_score),
    avg_engagement     = mean(engagement_intensity),
    churn_rate         = mean(as.numeric(as.character(churn)))
  )

cluster_profile
# these averages help you describe each cluster in simple terms

# cluster profile notes you can use in your paper:
# cluster 1 has about 1592 customers with average tenure about 18 months and average order count about 2.5
# cluster 2 has about 3264 customers with average tenure about 6 months and average order count about 1.7
# cluster 3 has about 774 customers with average tenure about 12 months and average order count about 9
# cluster 2 has the highest churn rate, cluster 3 has the lowest churn rate
# this shows churn risk is not the same for every customer group

#---------4.4 optional: simple visual check---------
plot(
  cluster_vars$order_count,
  cluster_vars$approx_clv,
  col = store_imputed$cluster_k3,
  pch = 19,
  xlab = "order_count",
  ylab = "approx_clv",
  main = "k-means clusters (k = 3) on order_count vs approx_clv"
)