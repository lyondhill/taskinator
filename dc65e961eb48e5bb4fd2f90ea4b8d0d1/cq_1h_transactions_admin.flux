// CREATE CONTINUOUS QUERY
//     cq_1h_transactions_admin ON insights 
// RESAMPLE EVERY 5m FOR 2d 
// BEGIN 
// SELECT 
//     sum(transaction_count) AS transaction_count, sum(usd_amount) AS usd_amount, sum(amount) AS amount 
// INTO 
//     insights."14_days"."1h_transactions_admin"
// FROM 
//     insights."14_days"."1h_transactions" 
// GROUP BY 
//     time(1h), gateway_type, currency_code, transaction_type, transaction_state 
// END

option task = {
    name: "cq_1d_transactions_admin",
    every: 5m,
}

base = from(bucket: "insights/14_days") |> range(start: -24h) |> filter(fn: (r) => r._measurement = "1d_transactions") |> window(every: 1h)
finish = (table=<-) => table |> group(by: ["gateway_type", "currency_code", "transaction_type", "transaction_state"]) |> set(key: "_measurement", value: "1h_transactions_admin" ) |>  to(org: "b5e1b39b36674db8", bucket: "insights/14_days") 

base |> filter(fn: (r) => r._field == "transaction_count") |> sum() |> finish()
base |> filter(fn: (r) => r._field == "usd_amount") |> sum() |> finish()
base |> filter(fn: (r) => r._field == "amount") |> sum() |> finish()
