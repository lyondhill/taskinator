// CREATE CONTINUOUS QUERY
//     cq_5min_transactions ON insights 
// RESAMPLE EVERY 5m FOR 2d 
// BEGIN 
// SELECT 
//     count(amount) AS transaction_count, sum(usd_amount) AS usd_amount, sum(amount) AS amount 
// INTO 
//     insights."7_days"."5min_transactions" 
// FROM 
//     insights.autogen.transactions 
// GROUP BY 
//     time(5m), organization_key, environment_key, gateway_type, currency_code, transaction_type, transaction_state 
// END

option task = {
    name: "cq_5min_transactions",
    every: 5m,
}

base = from(bucket: "insights/autogen") |> range(start: -2d) |> filter(fn: (r) => r._measurement = "transactions") |> window(every: 5m)
finish = (table=<-) => table |> group(by: ["organization_key", "environment_key", "gateway_type", "currency_code", "transaction_type", "transaction_state"]) |> set(key: "_measurement", value: "5m_transactions" ) |>  to(org: "b5e1b39b36674db8", bucket: "insights/autogen") 

base |> filter(fn: (r) => r._field == "amount") |> count() |>  set(key: "_field", value: "transaction_count" ) |> finish()
base |> filter(fn: (r) => r._field == "usd_amount") |> sum() |> finish()
base |> filter(fn: (r) => r._field == "amount") |> sum() |> finish()
