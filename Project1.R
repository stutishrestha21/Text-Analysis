library(dplyr)
library(tidyverse)
library(readxl)
library(lubridate)
library(shiny)    
library(ggplot2)
library(DT)
library(sentimentr)
library(wordcloud)
library(tidytext)
library(textdata)
library(RColorBrewer)
library(reshape2)


rm(list=ls())

setwd("~/Desktop/DATA/Data 332/Project 1")

#read the data in the csv and then converted it into rds
#df_table<- read.csv('Consumer_Complaints.csv')
#saveRDS(df_table, "Consumer_Complaints.rds")

#we just saved the data as RDS so we now perform our code in this new rds format
data <- readRDS("Consumer_Complaints.rds")

#now we select the columns that we need and rename it
my_data <- data %>%
  select(Date.received, Product, Issue, Company, State, Submitted.via, Company.response.to.consumer, Timely.response., Consumer.disputed., Complaint.ID)%>%
  rename(Date_received = Date.received)%>%
  rename(Company_response = Company.response.to.consumer)%>%
  rename(Submitted_via = Submitted.via)%>%
  rename(Timely_Response = Timely.response.)%>%
  rename(Consumer_disputed = Consumer.disputed.)%>%
  rename(Consumer_ID = Complaint.ID)

#lowercase the issue for better analysis
my_data$Issue<- tolower(my_data$Issue)

#Select only 50,000 data at the beginning

my_data_50 <- my_data[1:50000, ]
my_data_50$Issue<- tolower(my_data_50$Issue)

#Restructure the data
data_df <- unnest_tokens(tbl = my_data, input = Issue, output = word)

#create data frame with stop words
stop_words <- get_stopwords(source = "smart")

#removing stop words
data_df <- anti_join(data_df, stop_words, by= "word")

#Sentiment analysis with Bing And joining and counting it

bing_table <- data_df %>%
  inner_join(get_sentiments("bing"))%>%
  count(word, Product, Company, State, Submitted_via, Consumer_disputed, Date_received, sentiment, sort = TRUE)%>%
  ungroup()

#making negative and positive  columns to get value of everything, might be helpful if I had positive an negative values for one word
bing_table <- spread(key = sentiment, value = n, fill =0, data = bing_table)
bing_table <- mutate(sentiment = positive - negative,
                     .data = bing_table)
#making bing table with just count and sentiment
bing_df <- data_df%>%
  inner_join(get_sentiments('bing'))%>%
  count(word, sentiment)%>%
  pivot_wider(names_from = sentiment, values_from = n, values_fill=0)%>%
  mutate(sentiment= positive- negative)

#Find a mean, More negative value then positive
mean(bing_table$sentiment, na.rm = TRUE)  

#Data Visualization: Bar chart of where people submitted and the sentiment value of it

ggplot(aes(x = Submitted_via, y= sentiment, fill = Submitted_via), data = bing_table) +
  geom_col(show.legend = TRUE)+
  facet_wrap(vars(), ncol = 1, scales = "free_x")+
  labs(x="Submitted Via", y ="Sentiment")+
  theme_classic()


#The word and the sentiment, how negative it is, altogether how much and how many
ggplot(aes(x = word, y= sentiment, fill = State), data = bing_table) +
  geom_col(show.legend = TRUE)+
  facet_wrap(vars(), ncol = 1, scales = "free_x")+
  labs(x="Word", y ="Sentiment")+
  theme_classic()

#Showing the word used in the product and how much sentiment it has
ggplot(bing_table, aes(word, sentiment, fill = Product)) +
  geom_col(show.legend = FALSE) +
  facet_wrap(~Product, ncol = 2, scales = "free_x")


#Word Cloud of neagtive words
set.seed(1234) # for reproducibility 
wordcloud(words = bing_df$word, freq = bing_df$negative, scale = c(4.0,0.75), 
          max.words=200,colors=brewer.pal(7, "Dark2"))

#Word Cloud of positive words
set.seed(1234) # for reproducibility 
wordcloud(words = bing_df$word, freq = bing_df$positive, scale = c(3.5,0.95), 
          max.words=200,colors=brewer.pal(3, "Dark2"))




  



