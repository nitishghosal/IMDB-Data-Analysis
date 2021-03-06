

library(tidyverse)
library(stringr)

url<-"https://raw.githubusercontent.com/nitishghosal/IMDB-Data-Analysis/master/movie_metadata.csv"

movie <- as_data_frame(read.csv(url,stringsAsFactors = FALSE,na="NA"))

#movie <- as_data_frame(read.csv('tmdb_5000_movies.csv',stringsAsFactors = FALSE,na="NA"))

#credits <- as_data_frame(read.csv('tmdb_5000_credits.csv',stringsAsFactors = FALSE,na="NA"))


glimpse(movie)


summary(movie)


#Data Cleaning

movie$movie_title <- substr(movie$movie_title,1,nchar(movie$movie_title)-1)
movie$genres_2 <- (sapply(movie$genres,gsub,pattern="\\|",replacement=" "))

movie = movie[!duplicated(movie$movie_title),]
movie$profit_flag <- as.factor(ifelse((movie$gross > movie$budget),1,0))

dim(movie)

##Genre Analysis


library(tm)
library(dplyr)
library(ggplot2)
library(wordcloud)
genre <- Corpus(VectorSource(movie$genres_2))
genre_dtm <- DocumentTermMatrix(genre)
genre_freq <- colSums(as.matrix(genre_dtm))
freq <- sort(colSums(as.matrix(genre_dtm)), decreasing=TRUE) 
genre_wf <- data.frame(word=names(genre_freq), freq=genre_freq)

ggplot(genre_wf, aes(x=reorder(word,-freq), y=freq))+ 
  geom_bar(stat="identity")+
  theme(axis.text.x = element_text(angle=90),plot.title=element_text(color="Black",face="bold"),legend.position="none")+
  #theme(axis.text.x=element_text(angle=45, hjust=1))+
  ggtitle("Distribution of Movies by Genre")+
  xlab("Genre")+
  ylab("No of Movies")


set.seed(1)
pal2 <- brewer.pal(8,"Dark2")
wordcloud(genre_wf$word,genre_wf$freq,random.order=TRUE,
          rot.per=.15, colors=pal2,scale=c(4,.9),
          title="Sentiment Analysis of Movie Genre")


library(plotly)

genres<-movie$genres
test<-NULL
for(i in 1:length(genres)){
  str<-strsplit(genres[i], "|", fixed = TRUE)[[1]]
  test<-c(test,str)
}

ttable<-table(test)
newtest<-data.frame(ttable)
plot_ly(newtest,labels = ~test,textinfo = 'label+percent', values = ~Freq) %>%
  add_pie(hole = 0.6)


## Top 10 by different categories



#Top 10 highest grossing movies

movie %>% drop_na(movie_title)%>%
  arrange(desc(gross)) %>% 
  head(10) %>%  
  ggplot(aes(reorder(movie_title,gross),gross,fill=movie_title))+
  geom_bar(stat="identity")+
  theme(axis.text.x = element_text(angle=90),plot.title=element_text(color="Black",face="bold"),legend.position="none")+
  scale_y_continuous(labels=scales::comma)+
  labs(x="",y="Total Gross in USD",title="Top 10 highest grossing movies")


#Bottom 10 grossing movies
movie %>% drop_na(movie_title,gross)%>%
  arrange(desc(gross)) %>% 
  tail(10) %>%  
  ggplot(aes(reorder(movie_title,gross),gross,fill=movie_title))+
  geom_bar(stat="identity")+
  theme(axis.text.x = element_text(angle=90),plot.title=element_text(color="Black",face="bold"),legend.position="none")+
  scale_y_continuous(labels=scales::comma)+
  labs(x="",y="Total Gross in USD",title="Top 10 lowest grossing movies")


#Top 10 most profitable movies
movie$profit <- movie$gross - movie$budget

movie %>% drop_na(movie_title,profit)%>%
  arrange(desc(profit)) %>% 
  head(10) %>%  
  ggplot(aes(reorder(movie_title,profit),profit,fill=movie_title))+
  geom_bar(stat="identity")+
  theme(axis.text.x = element_text(angle=90),plot.title=element_text(color="Black",face="bold"),legend.position="none")+
  scale_y_continuous(labels=scales::comma)+
  labs(x="",y="Total Profit in USD",title="Top 10 most profitable movies")


#Top 10 least profitable movies
movie$loss <- movie$budget - movie$gross

movie %>% drop_na(movie_title,loss)%>%
  arrange(desc(loss)) %>% 
  head(10) %>%  
  ggplot(aes(reorder(movie_title,loss),loss,fill=movie_title))+
  geom_bar(stat="identity")+
  theme(axis.text.x = element_text(angle=90),plot.title=element_text(color="Black",face="bold"),legend.position="none")+
  scale_y_continuous(labels=scales::comma)+
  labs(x="",y="Total Loss in USD",title="Top 10 least profitable movies")

#Top 10 most popular movies

movie %>% drop_na(movie_title,num_voted_users)%>%
  arrange(desc(num_voted_users)) %>% 
  head(10) %>%  
  ggplot(aes(reorder(movie_title,num_voted_users),num_voted_users,fill=movie_title))+
  geom_bar(stat="identity")+
  theme(axis.text.x = element_text(angle=90),plot.title=element_text(color="Black",face="bold"),legend.position="none")+
  scale_y_continuous(labels=scales::comma)+
  labs(x="",y="Total Number of User Votes",title="Top 10 most popular movies")


# Relation between IMDB Score, Revenue & Budget
plot_ly(movie, x = ~imdb_score, y = ~budget/1000000, z = ~gross/1000000, 
        color = ~profit_flag,size = I(3),
        hoverinfo = 'text',
        text = ~paste('Movie: ', movie_title,
                      '</br></br> Gross: ', gross,
                      '</br> Budget: ', budget,
                      '</br> IMDB Score: ', imdb_score)) %>%
  add_markers() %>%
  layout(scene = list(xaxis = list(title = 'IMDB Score'),
                      yaxis = list(title = 'Budget'),
                      zaxis = list(title = 'Revenue')),
         title = "IMDB Score vs Revenue vs Budget",
         showlegend = FALSE)


## Analysis By Country

# Top 10 countries by average profit per country
movie %>%
  group_by(country) %>%
  summarise(num = n_distinct(movie_title),
            average_profit = mean(profit,na.rm="true")) %>%
  arrange(-average_profit) %>%
  head(10) %>%
  ggplot(aes(reorder(country,average_profit),average_profit,fill=country))+
  #ggplot(aes(reorder(country,-num),num),fill=country)+
  geom_bar(stat = "identity")+
  theme(axis.text.x = element_text(angle=90),plot.title=element_text(color="Black",face="bold"),legend.position="none")+
  scale_y_continuous(labels=scales::comma)+
  xlab("")+ylab("Average Profit per Movie in USD")+
  ggtitle("Top countries by average profit per film")

#Top 10 countries by average IMDB rating per movie
movie %>%
  group_by(country) %>%
  summarise(num = n_distinct(movie_title),
            average_rating = mean(imdb_score,na.rm = "true")) %>%
  arrange(-average_rating) %>%
  head(10) %>%
  ggplot(aes(reorder(country,average_rating),average_rating,fill=country))+
  #ggplot(aes(reorder(country,-num),num),fill=country)+
  geom_bar(stat = "identity")+
  theme(axis.text.x = element_text(angle=90),plot.title=element_text(color="Black",face="bold"),legend.position="none")+
  xlab("")+ylab("Average IMDB rating")+
  ggtitle("Top countries by average IMDB rating of movies")

# Top 10 countries by average budget per film
movie %>%
  group_by(country) %>%
  summarise(num = n_distinct(movie_title),
            average_budget = mean(budget,na.rm="true")) %>%
  arrange(-average_budget) %>%
  head(10) %>%
  ggplot(aes(reorder(country,average_budget),average_budget,fill=country))+
  #ggplot(aes(reorder(country,-num),num),fill=country)+
  geom_bar(stat = "identity")+
  theme(axis.text.x = element_text(angle=90),plot.title=element_text(color="Black",face="bold"),legend.position="none")+
  scale_y_continuous(labels=scales::comma)+
  xlab("")+ylab("Average Budget per Movie in USD")+
  ggtitle("Top countries by average budget per film")



## Best Directors & Actors

general_table = movie %>% group_by(director_name) %>% 
  summarise(mean_imdb = mean(imdb_score, na.rm=T), 
            total_movies = n(), 
            standard_dev = sd(imdb_score), 
            lower_bound = mean_imdb- 2* standard_dev/sqrt(total_movies), 
            upper_bound = mean_imdb+ 2* standard_dev/sqrt(total_movies)) %>% 
  arrange(desc(mean_imdb))

total_movies_mean = mean(general_table$total_movies)

director_final = general_table %>%  na.omit()
director_final = director_final%>% slice(1:30)

director_final$director_name = factor(director_final$director_name, levels= director_final$director_name[order(director_final$mean_imdb)])

ggplot(director_final, aes(x = mean_imdb , xmin = lower_bound, xmax = upper_bound, y = director_name)) + geom_point() + geom_segment( aes(x = lower_bound, xend = upper_bound, y = director_name, yend=director_name)) + theme(axis.text=element_text(size=8)) + xlab("Mean IMDB Rating") + ylab("Director") + ggtitle("Best Directors by Movie Rating") + theme_bw() 


lead_actor_table = movie %>% group_by(actor_1_name) %>% 
  summarise(mean_imdb = mean(imdb_score, na.rm=T), 
            total_movies = n(), 
            standard_dev = sd(imdb_score), 
            lower_bound = mean_imdb- 2* standard_dev/sqrt(total_movies), 
            upper_bound = mean_imdb+ 2* standard_dev/sqrt(total_movies) ) %>% 
  arrange(desc(mean_imdb))


lead_actor_table = subset(lead_actor_table, lead_actor_table$actor_1_name != "")

actor_mean_movies = mean(lead_actor_table$total_movies)

lead_actor_table = lead_actor_table %>% filter(total_movies >= 3)

top_30_actors = lead_actor_table %>% slice(1:30)

top_30_actors$actor_1_name = factor(top_30_actors$actor_1_name, levels = top_30_actors$actor_1_name[order(top_30_actors$mean_imdb)])

ggplot(top_30_actors, aes(x = mean_imdb, xmin = lower_bound, xmax = upper_bound, y = actor_1_name)) +
  geom_point() + 
  geom_segment( aes(x = lower_bound, xend = upper_bound, y = actor_1_name, yend=actor_1_name)) + 
  theme(axis.text=element_text(size=8)) + 
  xlab("Mean Movie Rating") + ylab("Lead Actor") + 
  ggtitle("Best Actors by IMDB Movie Rating") + theme_bw()


## Correlation Matrix for important variables

library(corrgram)

corrgram_data <- movie %>% 
  dplyr::select(., duration, num_critic_for_reviews, gross,  num_voted_users, num_user_for_reviews, budget, title_year, imdb_score, movie_facebook_likes)


corrgram(corrgram_data,legend=T)




