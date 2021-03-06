#Update the tables sensor_sparkling_lake_watertemp_hi_res and ios_app_sp for Sparkling Lake
#This should be run hourly. For simplicity, treating data for the two tables separately.
library(RMySQL)

latestFile <- "/triton/BuoyData/SP/sp_latest_limno.csv"

if (file.exists(latestFile)) {
  
  df.A <- read.csv(latestFile,header=T,stringsAsFactors=FALSE)
  nrecords <- nrow(df.A)
  #nrecords <- 1
  
  ###Connect to the database
  conn <- dbConnect(MySQL(),dbname="dbmaker", client.flag=CLIENT_MULTI_RESULTS)  
  
  ##################### To sensor_sparkling_lake_watertemp_hi_res ############################
  
  nfields <- 8
  ###Assign field names. These must match the database field names
  fields <- c("sampledate","year4","month","daynum","sampletime","depth","wtemp","flag_wtemp")
  ### Assign formatting to each field. Strings (%s) get extra single quotes
  fmt <- c("'%s'","%.0f","%.0f","%.0f","'%s'","%.2f","%.3f","'%s'")
  
  ### Assign local variables, must use the same name as database field
  for (r in 1:nrecords) {
    sampledate <- df.A[r,1]
    year4 <- df.A[r,2]
    month <- df.A[r,3]
    daynum <- df.A[r,4]
    sampletime <- df.A[r,5]
    depth <- df.A[r,6]
    wtemp <- df.A[r,7]
    flag_wtemp <- df.A[r,8]

    ###Create the mask that says which field have valued entries
    mask<-0  
    for (i in 1:nfields) {
      value <- eval(parse(text=fields[i]))
      if ( is.na(value) || (value=="")) {mask[i]<-0} else {mask[i]<-1}
    }
      
    ###Develop a SQL command
    sql <- "insert ignore into sensor_sparkling_lake_watertemp_hi_res ("
    for (i in 1:nfields) {
      if (mask[i]) { sql <- paste(sql,fields[i],",",sep="") }  #valued fields
    }
    sql <- substr(sql,1,nchar(sql)-1)  #remove last comma and extend
    sql <- paste(sql,") values (",sep="")
    for (i in 1:nfields) {
      if (mask[i]) { sql <- paste(sql,fmt[i],",",sep="") }     #add fmts of valued fields
    }
    sql <- substr(sql,1,nchar(sql)-1) #remove last comma and close
    sql <- paste(sql,")",sep="") 
  
  
    ###Build a string of the sprintf function. This puts values into fields.
    scmd <- "sprintf(sql,"
    for (i in 1:nfields) {
     if (mask[i]) { scmd <- paste(scmd,fields[i],",",sep="") } #field values
    }
    scmd <- substr(scmd,1,nchar(scmd)-1) #remove last comma and clean up
    scmd <- paste(scmd,")",sep="") 
    #print(scmd)
  
    ###Get the SQL command back by parsing
    sql <- eval(parse(text=scmd))
    #sql <- paste(sql,"IGNORE",sep=" ")
    #print(sql)
    result <- dbGetQuery(conn,sql)  
    
  }#for

  
  ##################### To ios_app_sp ############################
    
  ### Get the average value for 0.25m watertemp, must use the same name as database field
  wt_sum <- 0
  nsamps <- 0
  for (r in 1:nrecords) {
    if (df.A[r,6] == 0.25) {
      nsamps <- nsamps+1
      wt_sum <- wt_sum + df.A[r,7]
    }
  }
  water_temp <- wt_sum/nsamps
  
  #Get sampledate from dataframe but in CST; Convert to CDT
  tmpdate <- as.POSIXct(df.A[1,1],tz="America/Guatemala")
  sampledate <- format(tmpdate,tz="America/Chicago")
  lt <- strptime(sampledate,tz="America/Chicago",format="%Y-%m-%d %H:%M:%S")
  hour <- 100*as.numeric(format(lt,"%H"))
   
  date <- as.character(format(lt,"%Y-%m-%d"))
  date <- paste0("'",date,"'")     
  ###Develop a SQL command
  sql <- "update ios_app_sp set water_temp="
  sql <- paste0(sql,as.character(water_temp)," where hour=",as.character(hour)," and sampledate=",date)
  
  print(sql)
  result <- dbGetQuery(conn,sql)  
  
  ###Disconnect from the database
  dbDisconnect(conn) 
  file.remove(latestFile)
  message("Latest SP limno updated")
}#if
