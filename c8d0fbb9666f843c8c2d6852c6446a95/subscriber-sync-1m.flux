//CREATE CONTINUOUS QUERY 
//    "subscriber-sync-1m" ON consumers 
//BEGIN 
//SELECT 
//    percentile(message_age, 95) AS message_age, 
//    percentile(processing_time, 95) AS processing_time, 
//    sum("rebuild.conflict") AS rebuild_conflict, 
//    count(processing_time) AS messages_processed 
//INTO 
//    consumers."1year"."subscriber-sync-1m" 
//FROM 
//    consumers."2weeks"."subscriber-sync" 
//GROUP BY 
//    time(1m), consumer, acked, environment, error, event_type, exception, redelivered, requeued, version 
//END

option task = {
    name: "subscriber-sync-1m",
    every: 1m,
    delay: 5m,
}

base = from(bucket: "consumers/2weeks") |> range(start: -task.every) |> filter(fn: (r) => r._measurement == "subscriber-sync" )
toBucket = (table=<-) => table |> set(key: "_measurement", value: "subscriber-sync-1m" ) |>  to(org: "0492cb87e4ea2a22", bucket: "consumers/1year") 
groupBy = (table=<-) => table |> group(by: ["consumer", "acked", "environment", "error", "event_type", "exception", "redelivered", "requeued", "version"]) |> window(every: task.every) 

base |> filter(fn: (r) => r._field == "message_age" ) |> groupBy() |> percentile(percentile: 95) |> toBucket()
base |> filter(fn: (r) => r._field == "processing_time" ) |> groupBy() |> percentile(percentile: 95) |> toBucket()
base |> filter(fn: (r) => r._field == "rebuild.conflict" ) |> set(key: "_field", value: "rebuild_conflict")|> groupBy() |> sum() |> toBucket()
base |> filter(fn: (r) => r._field == "processing_time" ) |> set(key: "_field", value: "messages_processed") |> groupBy() |> count() |> toBucket()
