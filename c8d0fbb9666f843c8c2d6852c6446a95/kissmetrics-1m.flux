//CREATE CONTINUOUS QUERY 
//    "kissmetrics-1m" ON consumers 
//BEGIN 
//SELECT 
//    percentile(message_age, 95) AS message_age, 
//    percentile(processing_time, 95) AS processing_time, 
//    percentile(put_record, 95) AS put_record, 
//    count(processing_time) AS events_processed 
//INTO 
//    consumers."1year"."kissmetrics-1m" 
//FROM 
//    consumers."2weeks".kissmetrics 
//GROUP BY 
//    time(1m), consumer, acked, environment, error, event_type, exception, redelivered, requeued, stream, version 
//END

option task = {
    name: "kissmetrics-1m",
    every: 1m,
    delay: 5m,
}

base = from(bucket: "consumers/2weeks") |> range(start: -task.every) |> filter(fn: (r) => r._measurement == "kissmetrics" )
toBucket = (table=<-) => table |> set(key: "_measurement", value: "kissmetrics-1m" ) |>  to(org: "0492cb87e4ea2a22", bucket: "consumers/1year") 
groupBy = (table=<-) => table |> group(by: ["consumer", "acked", "environment", "error", "event_type", "exception", "redelivered", "requeued", "stream", "version"]) |> window(every: task.every) 

base |> filter(fn: (r) => r._field == "message_age" ) |> groupBy() |> percentile(percentile: 0.95) |> toBucket()
base |> filter(fn: (r) => r._field == "processing_time" ) |> groupBy() |> percentile(percentile: 0.95) |> toBucket()
base |> filter(fn: (r) => r._field == "put_record" ) |> groupBy() |> percentile(percentile: 0.95) |> toBucket()
base |> filter(fn: (r) => r._field == "processing_time" ) |> set(key: "_field", value: "events_processed") |> groupBy() |> count() |> toBucket()
