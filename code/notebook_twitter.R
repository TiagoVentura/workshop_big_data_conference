## ---------------------------------------------------------------------------------------------------------------------
# Call packages using pacman
#install.packages("pacman")
pacman::p_load(here, jsonlite, tidyverse, academictwitteR)


## ---- eval=FALSE------------------------------------------------------------------------------------------------------
## # Using Academic Twitter to add yourkey
## set_bearer()
## 
## # Collect data
## tweets <-
##   get_all_tweets(
##     query = "(eleicoes2022 OR lula OR bolsonaro OR ciro OR tebet)", # query
##     start_tweets = "2022-10-01T00:00:00Z", #start time
##     end_tweets = "2022-10-04T00:00:00Z", #end time
##     file = "br_elections", # file to save
##     data_path = "data_br/", # folder where all data as jsons will be stores
##     n = 200000, # number of tweets
##     lang = "pt",
##   )


## ----eval=FALSE-------------------------------------------------------------------------------------------------------
## # data processing
## tweets_tidy <- bind_tweets("./data_br", output_format = "tidy")
## glimpse(tweets_tidy)


## ----echo=FALSE-------------------------------------------------------------------------------------------------------
# data processing
tweets_tidy <- read_rds("tweets_tidy.rds")
glimpse(tweets_tidy)


## ----eval=FALSE-------------------------------------------------------------------------------------------------------
## # examing the data
## tweets_raw <- bind_tweets("./data_br", output_format = "raw")
## str(tweets_raw, max.level=1)
## 


## ----echo=FALSE-------------------------------------------------------------------------------------------------------
# data processing
tweets_raw <- read_rds("tweets_raw_tidy.rds")
str(tweets_raw, max.level=1)


## ---------------------------------------------------------------------------------------------------------------------
# Filter retweets
tweets_tidy_rt <- tweets_tidy %>%
                          filter(!is.na(sourcetweet_type))

dim(tweets_tidy_rt)

# Visualize the dta
tweets_tidy_rt %>%
  select(user_username, sourcetweet_author_id) %>%
  head()



## ---------------------------------------------------------------------------------------------------------------------
# Create a edge list 
# using the user id on both sides here to keep the same unit

data <- cbind(tweets_tidy_rt$author_id, tweets_tidy_rt$sourcetweet_author_id)
dim(data)
head(data)



## ---------------------------------------------------------------------------------------------------------------------
pacman::p_load(igraph)

# Create an empty network

net <- graph.empty() 

# Add nodes
net <- add.vertices(net, 
                    length(unique(c(data))), # number of nodes
                    name=as.character(unique(c(data)))) # unique names

# Add edges
net <- add.edges(net, t(data))

# summary
summary(net)



## ---------------------------------------------------------------------------------------------------------------------
library(urltools)

# Edges 
E(net)$text <- tweets_tidy_rt$text
E(net)$idauth <- tweets_tidy_rt$sourcetweet_author_id
E(net)$namehub <- tweets_tidy_rt$user_username


# Capturing hashtags
E(net)$hash <- str_extract_all(tweets_tidy_rt$text, "#\\S+")


# grab expanded and unwound_url
entities <- tweets_raw$tweet.entities.urls

tidy_entities <- entities %>% 
                    # get columns we need
                    select(tweet_id, unwound_url) %>% 
                    #extract domains
                    mutate(unwound_url=domain(unwound_url)) %>%
                    # remove nas and combine multiple links
                    filter(!is.na(unwound_url)) %>%
                    group_by(tweet_id) %>%
                    summarise(domain=paste0(unwound_url, collapse=" -- "))

# Merge back with id
tweets_tidy_rt <- left_join(tweets_tidy_rt, tidy_entities)

# add to the network
E(net)$domain <- tweets_tidy_rt$domain


## ---------------------------------------------------------------------------------------------------------------------
# Calculate in degree and out degree
V(net)$outdegree<-degree(net, mode="out")
V(net)$indegree<-degree(net, mode="in")
summary(net)


## ----eval=FALSE-------------------------------------------------------------------------------------------------------
## l <- layout_with_fr(net, grid = c("nogrid"))
## #saveRDS(l, "layout.rds")
## head(l)


## ----echo=FALSE-------------------------------------------------------------------------------------------------------
l <- read_rds("layout.rds")
head(l)


## ----eval=FALSE-------------------------------------------------------------------------------------------------------
## my.com.fast <- walktrap.community(net)
## str(my.com.fast, max.level = 1)


## ----echo=FALSE-------------------------------------------------------------------------------------------------------
my.com.fast <- read_rds("community_detection.rds")
str(my.com.fast, max.level = 1)


## ---------------------------------------------------------------------------------------------------------------------
V(net)$l1 <- l[,1]
V(net)$l2 <- l[,2]
V(net)$membership <- my.com.fast$membership


## ---------------------------------------------------------------------------------------------------------------------

comunidades<- data_frame(membership=V(net)$membership)

comunidades %>% 
    count(membership) %>%
    arrange(desc(n)) %>%
    top_n(5)




## ----autoridade-------------------------------------------------------------------------------------------------------
# Create an datafram for the authoritiew
authorities <- data_frame(name=V(net)$name, ind=V(net)$indegree, 
                         membership=V(net)$membership) %>%
                          filter(membership==11| membership==4|membership==8) %>%
                          group_by(membership) %>%
                          arrange(desc(ind)) %>% 
                          slice(1:10)



## ---------------------------------------------------------------------------------------------------------------------
# I will get only from the 100 most retweeted to save some time. 
users_most_retweets <-authorities %>%
                      mutate(data_user=map(name, get_user_profile)) %>%
                      unnest()


# Main Communities
ggplot(users_most_retweets %>% filter(membership=="4"), aes(x=reorder(username,
                               ind, 
                               fill=membership),
                     y=ind)) + 
    geom_histogram(stat="identity", width=.5, color="black") +
    coord_flip() +
    xlab("") + ylab("") + 
    theme_minimal(base_size = 12) + 
    theme(plot.title = element_text(size = 22, face = "bold"), 
          axis.title=element_text(size=16), 
          axis.text = element_text(size=12, face="bold")) +
    facet_grid(~membership)

# Main Communities
ggplot(users_most_retweets %>% filter(membership=="11"), aes(x=reorder(username,
                               ind, 
                               fill=membership),
                     y=ind)) + 
    geom_histogram(stat="identity", width=.5, color="black") +
    coord_flip() +
    xlab("") + ylab("") + 
    theme_minimal(base_size = 12) + 
    theme(plot.title = element_text(size = 22, face = "bold"), 
          axis.title=element_text(size=16), 
          axis.text = element_text(size=12, face="bold")) +
    facet_grid(~membership)

# Main Communities
ggplot(users_most_retweets %>% filter(membership=="8"), aes(x=reorder(username,
                               ind, 
                               fill=membership),
                     y=ind)) + 
    geom_histogram(stat="identity", width=.5, color="black") +
    coord_flip() +
    xlab("") + ylab("") + 
    theme_minimal(base_size = 12) + 
    theme(plot.title = element_text(size = 22, face = "bold"), 
          axis.title=element_text(size=16), 
          axis.text = element_text(size=12, face="bold")) +
    facet_grid(~membership)


## ---------------------------------------------------------------------------------------------------------------------

# A function with the density. Nice to visualize as well.
my.den.plot <- function(l=l,new.color=new.color, ind=ind, legend, color){
  library(KernSmooth)
  est <- bkde2D(l, bandwidth=c(10, 10))
  plot(l,cex=log(ind+1)/4, col=new.color, pch=16, xlim=c(-160,140),ylim=c(-140,160), xlab="", ylab="", axes=FALSE)
   legend("topright", c(legend[1],legend[2], legend[3]), pch = 17:19, col=c(color[1], color[2], color[3]))
  contour(est$x1, est$x2, est$fhat,  col = gray(.6), add=TRUE)
  #text(-140,115,paste("ENCG: ",ENCG,sep=""), cex=1, srt=0)
} 

# Add colors for each community
# Building a empty container
temp <- rep(1,length(V(net)$membership))
new.color <- "white"
new.color[V(net)$membership==11] <- "Yellow" ####
new.color[V(net)$membership==8] <- "pink" ####
new.color[V(net)$membership==4] <- "red" ####

# Save as a variable in the network object
V(net)$new.color <- new.color

# Plot
my.den.plot(l=cbind(V(net)$l1,V(net)$l2),new.color=V(net)$new.color, ind=V(net)$indegre, legend =c("Pro-Bolsonaro", "Anti-Bolsonaro I", "Anti-Bolsonaro II"), 
color =c("Yellow", "red", "pink"))



## ---------------------------------------------------------------------------------------------------------------------
hashtags <- tweets_tidy_rt %>% 
            mutate(hashtags=str_extract_all(tweets_tidy_rt$text, "#\\S+")) %>%
            unnest(hashtags) %>%
            count(hashtags) %>%
            arrange(desc(n)) %>% 
            slice(1:30) %>%
            drop_na()
          

# Contando as hashtags
ggplot(hashtags, aes(x=reorder(hashtags,
                               n),
                     y=n)) + 
    geom_histogram(stat="identity", width=.5, color="black", 
                   fill="steelblue") +
  coord_flip() +
    xlab("") + ylab("") + 
  theme_minimal(base_size = 12) + 
  theme(plot.title = element_text(size = 22, face = "bold"), 
        axis.title=element_text(size=16), 
        axis.text = element_text(size=12, face="bold")) 




## ---------------------------------------------------------------------------------------------------------------------

# get communities
auth <- data_frame(name=V(net)$name, membership=V(net)$membership)

# merge

data_hash <- tweets_tidy_rt %>%
                    left_join(auth, by=c("author_id"="name")) %>%
                    mutate(hashtags=str_extract_all(tweets_tidy_rt$text, "#\\S+")) %>%
                    unnest(hashtags) %>%
                    drop_na(hashtags)
      

# Vamos aggrupar por comunidade
hash_by_comm <- data_hash %>%
                           filter(membership==11| membership==8|membership==4) %>%
                           count(membership, hashtags) %>%
                           top_n(20, n)

ggplot(hash_by_comm, aes(x=reorder(hashtags,
                               n),
                     y=n, fill=as.factor(membership))) + 
  geom_histogram(stat="identity", width=.5, color="black") +
  coord_flip() +
    xlab("") + ylab("") + 
  scale_fill_manual(name="Communities", values=c("Red", "pink", "Yellow")) +
  theme_minimal(base_size = 10) + 
  facet_wrap(~membership, scale="free") 


## ---------------------------------------------------------------------------------------------------------------------
summary(net)

# Vamos primeiro selecionar as mídias mais ativadas
keynews <- head(sort(table(unlist(E(net)$domain)),decreasing=TRUE),20)
keynews.names <- names(keynews)

N<-length(keynews.names)
count.keynews<- array(0,dim=c(length(E(net)),N))
str(count.keynews)

# Looping 
for(i in 1:N){
  temp<- grepl(keynews.names[i], E(net)$domain, ignore.case = TRUE)
  #temp <- str_match(E(net)$text,'Arangur[A-Za-z]+[A-Za-z0-9_]+')
  count.keynews[temp==TRUE,i]<-1
  Sys.sleep(0.1)

  }


# Setting the names of the media
colnames(count.keynews)<- keynews.names
count.keynews[1:5, 1:3]


## ---- eval=FALSE------------------------------------------------------------------------------------------------------
## 
## # Recovering all nodes connections
## el <- get.adjedgelist(net, mode="all")
## al <- get.adjlist(net, mode="all")


## ---- echo=FALSE------------------------------------------------------------------------------------------------------
# Recovering all nodes connections
el <- read_rds("el.rds")
al <- read_rds("al.rds")



## ---------------------------------------------------------------------------------------------------------------------

#Function to detect the spread in the adj list
fomfE<- function(var=var, adjV=adjV,adjE=adjE){
  stemp <- map_dbl(adjE, function(x) sum(var[x]))
  #mstemp <- sapply(adjV, function(x) mean(stemp[x]))
  out<-cbind(stemp)
}

# container
result_hash<- array(0,dim=c(length(V(net)),N))
# Repita para cada uma das hashtags
for(i in 1:N){
  bb<-fomfE(count.keynews[,i],al,el)
  bb[bb[,1]=="NaN"]<-0
  result_hash[,i]<- bb[,1]
}
colnames(result_hash)<- keynews.names



## ---------------------------------------------------------------------------------------------------------------------

par(mfrow=c(2,2))

# Hashtag 
plot(V(net)$l1,V(net)$l2,pch=16,  
       col=V(net)$new.color, 
       cex=log(result_hash[,1]+1),
       xlim=c(-100,150),ylim=c(-100,150), xlab="", ylab="",
       main=colnames(result_hash)[1], cex.main=1)

# Hashtag
plot(V(net)$l1,V(net)$l2,pch=16,  
       col=V(net)$new.color, 
      cex=log(result_hash[,7]+1),
       xlim=c(-100,150),ylim=c(-100,150), xlab="", ylab="",
       main=colnames(result_hash)[7], cex.main=1)
# Hashtag 
plot(V(net)$l1,V(net)$l2,pch=16,  
       col=V(net)$new.color, 
       cex=log(result_hash[,9]+1),
       xlim=c(-100,150),ylim=c(-100,150), xlab="", ylab="",
       main=colnames(result_hash)[9], cex.main=1)

# Hashtag
plot(V(net)$l1,V(net)$l2,pch=16,  
       col=V(net)$new.color, 
       cex=log(result_hash[,10]+1),
       xlim=c(-100,150),ylim=c(-100,150), xlab="", ylab="",
       main=colnames(result_hash)[10], cex.main=1)



## ---- echo=FALSE------------------------------------------------------------------------------------------------------
dev.off()


## ---------------------------------------------------------------------------------------------------------------------
# getting some Twitter Ids
pelosi <- get_user_id("SpeakerPelosi")


## ---------------------------------------------------------------------------------------------------------------------
pelosi_network <- get_user_following(pelosi)
glimpse(pelosi_network)


## ---------------------------------------------------------------------------------------------------------------------
#devtools::install_github("pablobarbera/twitter_ideology/pkg/tweetscores")
library(tweetscores)
results <- estimateIdeology("SpeakerPelosi", pelosi_network$id, verbose = FALSE)
plot(results)


## ---------------------------------------------------------------------------------------------------------------------
pelosi_tl = get_user_timeline(pelosi,
                              start_tweets = "2022-01-01T00:00:00Z", 
                               end_tweets = "2022-10-22T00:00:00Z", 
                              n=100) #limit
glimpse(pelosi_tl)


## ---------------------------------------------------------------------------------------------------------------------
pelosi_likes = get_liked_tweets(pelosi) #limit
glimpse(pelosi_likes) # she mostly liked her own tweets


