//CREATE CONTINUOUS QUERY 
//    "mailpoll-1m" ON services 
//BEGIN 
//SELECT 
//    percentile("duration", 95) AS "duration", 
//    percentile("duration", 98) AS "max-duration", 
//    percentile(content_length, 95) AS content_length, 
//    count("duration") AS requests 
//INTO 
//    services."1year"."mailpoll-rollup" 
//FROM 
//    services."1hour".mailpoll 
//GROUP BY 
//    time(1m), environment, endpoint, handler, method, status_code 
//END

option task = {
    name: "mailpoll-1m",
    every: 1m,
    delay: 5m,
}

base = from(bucket: "services/1hour") |> range(start: -task.every) |> filter( fn: (r) => r._measurement == "mailpoll") |> window(every: task.every) |> group(by: ["environment", "endpoint", "handler", "method", "status_code"]) 
toBucket = (table=<-) => table |> set(key: "_measurement", value: "mailpoll-rollup" ) |>  to(org: "0492cb87e4ea2a22", bucket: "services/1year") 

// content_length roll up
base |> filter(fn: (r) => r._field == "content_length") |> percentile(percentile: 0.95) |> toBucket()
duration |> percentile(percentile: 0.98) |> set(key: "_field", value: "max-duration") |> toBucket()

// duration roll up
duration = base |> filter( fn: (r) => r._field == "duration")
duration |> percentile(percentile: 0.95) |> toBucket()
duration |> count() |> set(key: "_field", value: "requests") |> toBucket()
