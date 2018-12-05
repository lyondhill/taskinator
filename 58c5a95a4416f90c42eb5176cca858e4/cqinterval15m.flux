//CREATE CONTINUOUS QUERY 
//    cqinterval15m ON wattvisiondb 
//RESAMPLE FOR 6h 
//BEGIN 
//SELECT 
//    first(watthours) AS watthours, 
//    mean(watts) AS watts 
//INTO 
//    wattvisiondb."default".sensor_reads_15m 
//FROM 
//    wattvisiondb."default".sensor_reads 
//GROUP BY 
//    time(15m), sensor_id, sensor_type 
//END

option task = {
    name: "cqinterval15m",
    every: 1h,
}

base = from(bucket: "wattvisiondb/default") 
|> range(start: -task.every * 6) 
|> filter(fn: (r) => r._measurement == "sensor_reads")
|> window(every: 15m)

finish = (table=<-) => table |> group(by: ["sensor_id", "sensor_type"]) |> set(key: "_measurement", value: "sensor_reads_15m" ) |>  to(org: "67631eeb30d3c975", bucket: "wattvisiondb/default") 

base |> filter(fn: (r) => r._field == "watthours") |> first() |> finish()
base |> filter(fn: (r) => r._field == "watts") |> mean() |> finish()