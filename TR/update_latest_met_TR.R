#Update the table sensor_trout_lake_russ_met_hi_res for Trout Lake
library(RMySQL)

latestFile <- "/triton/BuoyData/TR/tr_latest_met.csv"

if (file.exists(latestFile)) {
  
  df.A <- read.csv(latestFile,header=T,stringsAsFactors=FALSE)
  nrecords <- nrow(df.A)
  #nrecords <- 1
  
  nfields <- 41 
  
  ###Assign field names. These must match the database field names
  fields <- c("sampledate","year4","month","daynum","sampletime","data_freq","air_temp","flag_air_temp","rel_hum","flag_rel_hum",
              "wind_speed","flag_wind_speed","wind_dir","flag_wind_dir","barom_pres_mbar","flag_barom_pres_mbar","par","flag_par",
              "ysi_wtemp","flag_ysi_wtemp","ysi_spcond","flag_ysi_spcond","ysi_dosat","flag_ysi_dosat","ysi_do","flag_ysi_do",
              "sat_vapor_pres","flag_sat_vapor_pres","vapor_pres","flag_vapor_pres",
              "promini_co2_corr","flag_promini_co2_corr","promini_co2_bptemp","flag_promini_co2_bptemp","promini_co2_bp","flag_promini_co2_bp",
              "gp_co2_conc","flag_gp_co2_conc","gp_co2_temp","flag_gp_co2_temp","cumulative_precipitation")
              
              
  ### Assign formatting to each field. Strings (%s) get extra single quotes
  fmt <- c("'%s'","%.0f","%.0f","%.0f","'%s'","%.0f","%.3f","'%s'","%.1f","'%s'",
           "%.3f","'%s'","%.1f","'%s'","%.1f","'%s'","%.1f","'%s'",
           "%.2f","'%s'","%.1f","'%s'","%.1f","'%s'","%.2f","'%s'", 
           "%.3f","'%s'","%.3f","'%s'",
           "%.3f","'%s'","%.3f","'%s'","%.3f","'%s'",              
           "%.3f","'%s'","%.3f","'%s'","%.2f")

  
  ###Connect to the database
  conn <- dbConnect(MySQL(),dbname="dbmaker", client.flag=CLIENT_MULTI_RESULTS)   
  
  ### Assign local variables, must use the same name as database field
  for (r in 1:nrecords) {
    sampledate <- df.A[r,1]
    year4 <- df.A[r,2]
    month <- df.A[r,3]
    daynum <- df.A[r,4]
    sampletime <- df.A[r,5]
    data_freq <- df.A[r,6]
    air_temp <- df.A[r,7]
    flag_air_temp <- df.A[r,8]
    rel_hum <- df.A[r,9]
    flag_rel_hum <- df.A[r,10]
    wind_speed <- df.A[r,11]
    flag_wind_speed <- df.A[r,12]
    wind_dir <- df.A[r,13]
    flag_wind_dir <- df.A[r,14]
    barom_pres_mbar <- df.A[r,15]
    flag_barom_pres_mbar <- df.A[r,16]     
    par <- df.A[r,17]
    flag_par <- df.A[r,18]
    
    ysi_wtemp <- df.A[r,19]
    flag_ysi_wtemp <- df.A[r,20]
    ysi_spcond <- df.A[r,21]
    flag_ysi_spcond <- df.A[r,22]
    ysi_dosat <- df.A[r,23]
    flag_ysi_dosat <- df.A[r,24]
    ysi_do <- df.A[r,25]
    flag_ysi_do <- df.A[r,26]
    
    sat_vapor_pres <- df.A[r,27]
    flag_sat_vapor_pres <- df.A[r,28]    
    vapor_pres <- df.A[r,29]
    flag_vapor_pres <- df.A[r,30]

    promini_co2_corr <- df.A[r,31]    
    flag_promini_co2_corr <- df.A[r,32]    
    promini_co2_bptemp <- df.A[r,33]    
    flag_promini_co2_bptemp <- df.A[r,34]    
    promini_co2_bp <- df.A[r,35]    
    flag_promini_co2_bp <- df.A[r,36] 
    
    gp_co2_conc <- df.A[r,37]
    flag_gp_co2_conc <- df.A[r,38]
    gp_co2_temp <- df.A[r,39]
    flag_gp_co2_temp <- df.A[r,40]
  
    cumulative_precipitation <- df.A[r,41]

    ###Create the mask that says which field have valued entries
    mask<-0  
    for (i in 1:nfields) {
      value <- eval(parse(text=fields[i]))
      if ( is.na(value) || (value=="")) {mask[i]<-0} else {mask[i]<-1}
    }
      
    ###Develop a SQL command
    sql <- "insert ignore into sensor_trout_lake_russ_met_hi_res ("
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
  
  ###Disconnect from the database
  dbDisconnect(conn) 
  file.remove(latestFile)
}#if
