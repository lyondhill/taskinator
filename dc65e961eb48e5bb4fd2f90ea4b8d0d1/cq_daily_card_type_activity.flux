CREATE CONTINUOUS QUERY
    cq_daily_card_type_activity ON insights 
RESAMPLE EVERY 3h FOR 3d 
BEGIN 
SELECT 
    count(amount) AS transaction_count 
INTO 
    insights."2_years".daily_card_type_activity
FROM 
    insights.autogen.transactions 
GROUP BY 
    time(1d), card_type, transaction_state, transaction_type 
END


option task = {
    name: "cq_daily_card_type_activity",
    every: 3h,
}

from(bucket: "insights/90_days") 
|> range(start: -3d) 
|> filter(fn: (r) => r._measurement = "transactions" && r._field == "amount") 
|> window(every: 1d)
|> count() 
|>  set(key: "_field", value: "transaction_count" ) 
|> group(by: ["card_type", "transaction_state", "transaction_type"]) 
|> set(key: "_measurement", value: "daily_card_type_activity" ) 
|>  to(org: "b5e1b39b36674db8", bucket: "insights/2_years") 
