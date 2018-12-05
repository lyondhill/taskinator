// CREATE CONTINUOUS QUERY
//     cq_7d_transactions_admin ON insights 
// RESAMPLE EVERY 12h FOR 3d 
// BEGIN 
// SELECT 
//     sum(transaction_count) AS transaction_count, sum(usd_amount) AS usd_amount, sum(amount) AS amount 
// INTO 
//     insights."2_years"."7d_transactions_admin"
// FROM 
//     insights."2_years"."7d_transactions" 
// GROUP BY 
//     time(1d), gateway_type, currency_code, transaction_type, transaction_state 
// END


option task = {
    name: "cq_7d_transactions_admin",
    every: 1h,
}

base = from(bucket: "insights/2_years") |> range(start: -task.every * 36) |> filter(fn: (r) => r._measurement = "7d_transactions") |> window(every: 1d)
finish = (table=<-) => table |> group(by: ["gateway_type", "currency_code", "transaction_type", "transaction_state"]) |> set(key: "_measurement", value: "7d_transactions_admin" ) |>  to(org: "b5e1b39b36674db8", bucket: "insights/2_years") 

base |> filter(fn: (r) => r._field == "transaction_count") |> sum() |> finish()
base |> filter(fn: (r) => r._field == "usd_amount") |> sum() |> finish()
base |> filter(fn: (r) => r._field == "amount") |> sum() |> finish()
