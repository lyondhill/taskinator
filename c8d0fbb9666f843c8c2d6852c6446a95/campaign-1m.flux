//CREATE CONTINUOUS
//QUERY "campaign-1m" ON services 
//BEGIN 
//SELECT 
//    percentile("duration", 95) AS "duration", 
//    percentile("duration", 98) AS "max-duration", 
//    percentile(content_length, 95) AS content_length, 
//    count("duration") AS requests 
//INTO 
//    services."1year"."campaign-rollup"     
//FROM 
//    services."1hour".campaign 
//GROUP BY 
//    time(1m), environment, endpoint, handler, method, status_code 
//END

option task = {
    name: "campaign-1m",
    every: 1m,
    delay: 5m,
}

base = from(bucket: "services/1hour") |> range(start: -10m) |> filter( fn: (r) => r._measurement == "campaign")
toBucket = (table=<-) => table |> set(key: "_measurement", value: "campaign-rollup" ) |>  to(org: "0492cb87e4ea2a22", bucket: "services/1year") 
groupBy = (table=<-) => table |> group(by: ["environment", "endpoint", "handler", "method", "status_code"]) |> window(every: task.every) 

// content_length roll up
base |> filter(fn: (r) => r._field == "content_length") |> groupBy() |> percentile(percentile: 0.95) |> toBucket()

// duration roll up
duration = base |> filter( fn: (r) => r._field == "duration") |> groupBy()
duration |> percentile(percentile: 0.95) |> set(key: "_field", value: "duration") |> toBucket()
duration |> percentile(percentile: 0.98) |> set(key: "_field", value: "max-duration") |> toBucket()
duration |> count() |> set(key: "_field", value: "requests") |> toBucket()
