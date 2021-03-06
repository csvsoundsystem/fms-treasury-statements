#!/usr/bin/env Rscript
library(reshape2)
library(stringr)

strip <- function(string) {
    # Strip leading and trailing spaces
    str_replace(str_replace(string, '^ *', ''), ':? *$', '')
}

number <- function(string){
    # Remove the leading dollar sign, remove commas, and convert to numeric.
    as.numeric(str_replace_all(str_replace(strip(string), '^[$]?(?:[0-9]/)?', ''), ',', ''))
}

#                                                                Opening balance
#                                          Closing   ______________________________________
#           Type of account                balance                    This         This
#                                           today        Today        month       fiscal
#                                                                                  year
#___________________________________________________________________________________________

extra_chars <- function(string){
  string <- str_replace_all(strip(string),'1/', '')
  string <- str_replace_all(strip(string),'2/', '')
}

table1 <- function() {
    # Load file
    table1.wide <- read.fwf(
        'archive/12121400/table1.fixie',
        c(40, 12, 1, 12, 1, 12, 1, 13),
        stringsAsFactors = F
    )[,-c(3, 5, 7)]
    colnames(table1.wide) <- c('type', 'closing.balance.today', 'today', 'this.month', 'this.fiscal.year')
    table1.wide[2, 1] <- paste(strip(table1.wide[2:3, 1]), collapse = ' ')
    table1.wide <- table1.wide[-3,]

    table1.wide[1] <- strip(table1.wide[,1])
    table1.wide[-1] <- data.frame(lapply(table1.wide[-1], number))

    table1.wide
}


#___________________________________________________________________________________________
#     TABLE II  Deposits and Withdrawals of Operating Cash
#___________________________________________________________________________________________
#                                                                    This         Fiscal
#                    Deposits                          Today         month         year
#                                                                   to date      to date
#___________________________________________________________________________________________
#
#Federal Reserve Account:
#  Agriculture Loan Repayments (misc)              $          27 $         472 $       1,296


# Date,Table,Item,Type,Subitem,Today,MTD,FYT,Footnotes
# 11/29/2012,2,Agriculture Loan Repayments (misc),Deposits,,27,472,"1,296",

# Ignore the url for now.
table2 <- function(datestamp) {
    # Load file
    table2.wide <- read.fwf(
        paste('archive', datestamp, 'table2.fixie', sep = '/'),
        c(51, 13, 1, 13, 1, 13),
        stringsAsFactors = F
    )[,-c(3, 5)]

    table2.wide[1] <- strip(table2.wide[,1])

    colnames(table2.wide) <- c('item', 'today', 'mtd', 'ytd')
    table2.wide$date <- datestamp
    table2.wide$table <- 2

    table2.wide$footnotes <- ''
    table2.wide[!is.na(str_match(table2.wide[,2], '1/')),'footnotes'] <- '1'

    table2.wide$type <- factor(c(rep('deposit', 35), rep('withdrawal', 45)))
    table2.wide$is.total <- 0
    table2.wide[c(26, 34, 74, 80),'is.total'] <- 1

    table2.wide$subitem <- ''
    table2.wide[7:8,'subitem'] <- table2.wide[7:8,'item']
    table2.wide[7:8,'item'] <- 'Deposits by States' # table2.wide[6,'item']

    table2.wide[16,'item'] <- paste(table2.wide[15:16,'item'], collapse = ' ')

    table2.wide[22:26,'subitem'] <- table2.wide[22:26,'item']
    table2.wide[22:26,'item'] <- 'Other Deposits' # table2.wide[21,'item']
    table2.wide[26,'subitem'] <- ''

    table2.wide[28,'item'] <- paste(table2.wide[27:28,'item'], collapse = ' ')

    table2.wide[30,'subitem'] <- table2.wide[30,'item']
    table2.wide[30,'item'] <- table2.wide[29,'item']

    table2.wide[33,'subitem'] <- paste(table2.wide[32:33,'item'], collapse = ' ')
    table2.wide[33,'item'] <- table2.wide[31,'item']

    table2.wide[34,'item'] <- ''

    table2.wide[61,'item'] <- paste(table2.wide[60:61,'item'], collapse = ' ')

    table2.wide[66:73,'subitem'] <- table2.wide[66:73,'item']
    table2.wide[66:74,'item'] <- 'Other Withdrawals' # table2.wide[64,'item']
    table2.wide[74,'subitem'] <- ''

    table2.wide[76,'subitem'] <- table2.wide[76,'item']
    table2.wide[76,'item'] <- table2.wide[75,'item']

    table2.wide[79,'subitem'] <- paste(table2.wide[78:79,'item'], collapse = ' ')
    table2.wide[79,'item'] <- table2.wide[77,'item']

    table2.wide[80,'item'] <- ''

    table2.wide$url <- if (datestamp == '20121129') 'https://www.fms.treas.gov/fmsweb/viewDTSFiles?dir=a&fname=12112600.txt' else ''

    # Remove junk.
    table2.wide <- na.omit(table2.wide)

    # Make numeric.
    table2.wide[c('today', 'mtd', 'ytd')] <- data.frame(lapply(table2.wide[c('today', 'mtd', 'ytd')], number))

    # Arrange nicely.
    table2.wide[c('url', 'date', 'table',
        'type', 'item', 'subitem',
        'is.total', 'today', 'mtd', 'ytd', 'footnotes'
    )]
}
table3a <- function(datestamp, file){
  # Load file 
  alltables<-readLines(file)
  page4.line <- grep('PAGE',alltables)[4]
  print(page4.line)
  page5.line <- grep('PAGE',alltables)[5]
  print(page5.line)
  
  table3.wide <- read.fwf(file, c(40, 12, 1, 12, 1, 12, 1, 13), stringsAsFactors=F,skip=page4.line, n=page5.line-page4.line-1)[,-c(2,3,5,7)]
  # strip leading and trailing spaces  
  colnames(table3.wide) <- c('item', 'today', 'mtd', 'ytd')
  # Remove NA rows
  table3.wide <- na.omit(table3.wide)
  
  
  regular.series.line <- grep('Regular Series',table3.wide$item)[1]
  total.issues.line <- grep('Total Issues',table3.wide$item)[1]
  bills.line <- grep('Bills',table3.wide$item)[1]
  table3.wide$type <- factor(c(rep('Issues', total.issues.line), rep('Redemptions', nrow(table3.wide)-total.issues.line)))
  table3.wide <- table3.wide[-c(1:regular.series.line-1,(total.issues.line+1):(bills.line-1)),]
  table3.wide[1] <- strip(table3.wide[,1])
  table3.wide$date <- datestamp
  table3.wide$table <- 3
  table3.wide$datatype <- ifelse(table3.wide[,'item']=='Total Issues' | table3.wide[,'item']=='Total Redemptions','Total','Other')
  table3.wide[table3.wide[,'item']=='Net Change in Public Debt Outstanding','datatype'] = 'Net'
  table3.wide[c('today', 'mtd', 'ytd')] <- data.frame(lapply(table3.wide[c('today', 'mtd', 'ytd')], number))
  return(table3.wide)
}
table3c <- function(datestamp, file){
  # Load file and find location of table 
  alltables<-readLines(file)
  page6.line <- grep('PAGE',alltables)[6]
  page7.line <- grep('PAGE',alltables)[7]
  
  widths <- c(32, 15, 15, 15, 15)
  # Widths change in 2012 
  if(datestamp>='2012-06-01'){
    widths <- c(38, 15, 13,13,13)
  }
  
  # Messy. Two files have spacing issues. 
  if(datestamp=='2010-01-11' | datestamp=='2010-03-02'){
    table3.wide <- read.fwf(file, widths, stringsAsFactors=F,skip=page6.line, n=page7.line-page6.line+1,blank.lines.skip=T) 
  }
  else{  
    table3.wide <- read.fwf(file, widths, stringsAsFactors=F,skip=page6.line, n=32,blank.lines.skip=T)
  }
  colnames(table3.wide) <- c('balance_trans','closing_bal_today', 'opening_today', 'opening_mtd', 'opening_ytd')
  
  #remove NA values 
  table3.wide <- na.omit(table3.wide)
  
  gov.debt.line <- grep('Debt Held',table3.wide$balance_trans)[1]
  stat.debt.line <- grep('Statutory Debt Limit',table3.wide$balance_trans)[1]
  table3.wide <- table3.wide[gov.debt.line:stat.debt.line,]
  
  # strip leading and trailing spaces  
  table3.wide[1] <- strip(table3.wide[,1])
  table3.wide$date <- datestamp
  table3.wide$table <- 4
  table3.wide[c('closing_bal_today', 'opening_today', 'opening_mtd','opening_ytd')] <- data.frame(lapply(table3.wide[c('closing_bal_today', 'opening_today', 'opening_mtd','opening_ytd')], number))
  table3.wide[c('balance_trans')] <- data.frame(lapply(table3.wide[c('balance_trans')],extra_chars))
  return(table3.wide)
}
table5 <- function() {
    # Load file
    table5.wide <- read.fwf(
        'archive/12121400/table5.fixie',
        c(40, 12, 1, 12, 1, 12, 1, 13),
        stringsAsFactors = F
    )[-c(2, 7),c(1, 2, 4, 6, 8)]
    
    # Names
    rownames(table5.wide) <- 1:nrow(table5.wide)
    colnames(table5.wide) <- c('transaction', 'A', 'B', 'C', 'total')
    
    # Remove spaces.
    table5.wide[1] <- strip(table5.wide[,1])
    table5.wide[-1] <- data.frame(lapply(table5.wide[-1], number))
    
    # Income or expense?
    table5.wide$direction <- factor(c(rep('income', 5), rep('expense', 6)))
    
    table5.long <- melt(table5.wide, c('direction', 'transaction'),
        variable.name = 'type.of.depository', value.name = 'amount')
    table5.long
}

main <- function() {
    datestamp <- commandArgs(trailingOnly = T)[1]
    write.csv(table2(datestamp),
        file = paste('archive', datestamp, 'table2.csv', sep = '/'),
        row.names = F
    )
}

if (length(commandArgs(trailingOnly = T)) > 0){
    main()
}
