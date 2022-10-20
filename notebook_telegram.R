## #pip3 install telethon

## 


## # call some libraries

## import os

## import datetime

## import pandas as pd

## from dotenv import load_dotenv

## import json

## 

## # get the keys

## # load keys from  environmental var

## load_dotenv() # .env file in cwd

## telegram_id= os.environ.get("telegram_id")

## telegram_hash= os.environ.get("telegram_hash")

## 

## # also need your cellphone and username from telegram

## phone=os.environ.get("phone_number")

## username= os.environ.get("username")

## username

## 


## # call packages

## from telethon import TelegramClient

## from telethon.errors import SessionPasswordNeededError

## from telethon import sync

## 

## 

## # Create the client and connect

## def telegram_start(username, api_id, api_hash):

##   client = TelegramClient(username, api_id, api_hash)

##   client.start()

##   print("Client Created")

##   # Ensure you're authorized

##   if not client.is_user_authorized():

##       client.send_code_request(phone)

##       try:

##           client.sign_in(phone, input('Enter the code: '))

##       except SessionPasswordNeededError:

##           client.sign_in(password=input('Password: '))

##   return client

## 

## # Tun the function

## client = telegram_start(username, telegram_id, telegram_hash)

## 


## from telethon.tl.functions.channels import GetParticipantsRequest

## from telethon.tl.types import ChannelParticipantsSearch

## from telethon.tl.types import (PeerChannel)

## 

## # Let's get members of the Lula Channel on Telegram

## input_channel = "https://t.me/UrnasEletronicaseEleicoesBrasil"

## 

## ## Getting information from channel

## my_channel = client.get_entity(input_channel)

## 

## ## get channel members

## offset = 0

## limit = 500

## all_participants = []

## 

## while True:

##     participants = client(GetParticipantsRequest(

##         my_channel, ChannelParticipantsSearch(''), offset, limit,

##         hash=0

##     ))

##     if not participants.users:

##         break

##     all_participants.extend(participants.users)

##     offset += len(participants.users)

## 

## 

## 

## # Open Json

## all_user_details = []

## for participant in all_participants:

##     all_user_details.append(

##         {"id": participant.id, "first_name": participant.first_name, "last_name": participant.last_name,

##          "user": participant.username, "phone": participant.phone, "is_bot": participant.bot})

## 

## # Check it our

## df = pd.DataFrame(all_user_details)


## NA

## from telethon.tl.functions.messages import (GetHistoryRequest)

## from telethon.tl.types import (PeerChannel)

## import json

## 

## offset_id = 0

## limit = 1000

## all_messages = []

## total_messages = 0

## total_count_limit = 0

## 

## # capture data

## history = client(GetHistoryRequest(

##         peer=my_channel,

##         offset_id=offset_id,

##         offset_date=None,

##         add_offset=0,

##         limit=limit,

##         max_id=0,

##         min_id=0,

##         hash=0

##     ))

## 

## # get messages objects

## messages = history.messages

## 

## # convert to a dictionary

## for message in messages:

##       all_messages.append(message.to_dict())

## 

## # save json

## with open('data_telegram/message_data.json', 'w') as outfile:

##     json.dump(all_messages, outfile, indent=4, sort_keys=True, default=str)

## 


## # convert to pandas

## # Opening JSON file

## f = open('data_telegram/message_data.json')

## 

## # returns JSON object as

## # a dictionary

## data = json.load(f)

## 

## df = pd.DataFrame(data)

## df.keys()


## # open nested lists

## df = pd.concat([df, df["from_id"].apply(pd.Series)], axis=1)

## 

## # See

## df.head()

## 

