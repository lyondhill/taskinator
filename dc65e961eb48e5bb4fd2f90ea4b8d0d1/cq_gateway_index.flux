CREATE CONTINUOUS QUERY
    cq_gateway_index ON insights 
RESAMPLE EVERY 3h FOR 2d 
BEGIN 
SELECT 
    count(amount) AS transaction_count, sum(usd_amount) AS usd_amount, sum(amount) AS amount, sum(gateway_latency_ms) AS gateway_latency_ms 
INTO 
    insights.autogen.gateway_index_transactions
FROM 
    insights.autogen.transactions 
GROUP BY 
    time(1d), gateway_type, transaction_type, transaction_state, gateway_latency_present 
END

option task = {
    name: "cq_gateway_index",
    every: 3h,
}

base = from(bucket: "insights/autogen") |> range(start: -2d) |> filter(fn: (r) => r._measurement = "transactions") |> window(every: 5m)
finish = (table=<-) => table |> group(by: ["gateway_type", "transaction_type", "transaction_state", "gateway_latency_present"]) |> set(key: "_measurement", value: "gateway_index_transactions" ) |>  to(org: "b5e1b39b36674db8", bucket: "insights/autogen") 

base |> filter(fn: (r) => r._field == "amount") |> count() |>  set(key: "_field", value: "transaction_count" ) |> finish()
base |> filter(fn: (r) => r._field == "usd_amount") |> sum() |> finish()
base |> filter(fn: (r) => r._field == "amount") |> sum() |> finish()
base |> filter(fn: (r) => r._field == "gateway_latency_ms") |> sum() |> finish()
