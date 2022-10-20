## # run in the command line

## #pip install youtube-data-api


## # call some libraries

## import os

## import datetime

## import pandas as pd


## # pass your keys

## from youtube_api import YouTubeDataAPI

## from youtube_api.youtube_api_utils import *

## from dotenv import load_dotenv

## 

## # load keys from  environmental var

## load_dotenv() # .env file in cwd

## api_key = os.environ.get("YT_KEY")

## 

## # create a client

## yt = YouTubeDataAPI(api_key)


## channel_id = yt.get_channel_id_from_user('LastWeekTonight')

## print(channel_id)


## # collect metadata

## yt.get_channel_metadata(channel_id)


## pd.DataFrame(yt.get_subscriptions(channel_id))


## from youtube_api.youtube_api_utils import *

## playlist_id = get_upload_playlist_id(channel_id)

## print(playlist_id)

## 

## ## Get video ids

## videos = yt.get_videos_from_playlist_id(playlist_id)

## df = pd.DataFrame(videos)


## # id for videos as a list

## df.video_id.tolist()

## 

## #grab metadata

## video_meta = yt.get_video_metadata(df.video_id.tolist()[:5])

## 

## #visualize

## pd.DataFrame(video_meta[:2])

## 


## ids = df.video_id.tolist()[:5]

## 

## # loop

## list_comments = []

## for video_id in ids:

##   comments = yt.get_video_comments(video_id, max_results=10)

##   list_comments.append(pd.DataFrame(comments))

## 

## # concat

## df = pd.concat(list_comments)

## df.head()


## df = pd.DataFrame(yt.get_recommended_videos(ids[0]))

## df.channel_title

## 


## df = pd.DataFrame(yt.search(q='urnas, fraude', max_results=10))

## df.keys()

## df[["channel_title", "video_title"]]

