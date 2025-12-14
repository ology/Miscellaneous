import os
import re
from googleapiclient.discovery import build
from openai import OpenAI
from youtube_transcript_api import YouTubeTranscriptApi

MAX = 128000 # openai tokens
client = OpenAI()

def extract_video_id(url):
    # handle standard youtube.com and shortened youtu.be URLs
    regex = r"(?:v=|\/)([0-9A-Za-z_-]{11}).*"
    match = re.search(regex, url)
    if match:
        return match.group(1)
    return None

def get_transcript_text(video_id):
    try:
        ytt_api = YouTubeTranscriptApi()
        transcript_list = ytt_api.fetch(video_id)
        text = [ t.text for t in transcript_list.snippets ]
        return " ".join(text)
    except Exception as e:
        print(f"Error fetching transcript: {e}")
        return None

def get_video_comments(video_id, api_key):
    youtube = build('youtube', 'v3', developerKey=api_key)
    comments = []
    next_page_token = None

    while len(" ".join(comments)) < MAX:
        video_response = youtube.commentThreads().list(
            part='snippet',
            videoId=video_id,
            pageToken=next_page_token,
            maxResults=100
        ).execute()

        for item in video_response['items']:
            comment = item['snippet']['topLevelComment']['snippet']
            text = comment['textOriginal']
            comments.append(text)
            # {
            #     'author': author,
            #     'text': text,
            #     'published_at': publish_date,
            #     'likes': like_count
            # })

        # Check if there are more pages of comments
        next_page_token = video_response.get('nextPageToken')
        # If no next page token exists, the loop ends
        if not next_page_token:
            break

    return comments

def summarize_text(text):
    if not text:
        return
    print("Processing summary with AI... (this may take a moment)")
    try:
        response = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[
                {"role": "system", "content": "You are a helpful assistant that summarizes YouTube videos."},
                {"role": "user", "content": f"Please provide a concise bullet-point summary of the following text:\n\n{text}"}
            ],
            max_tokens=500,
            temperature=0.5
        )
        return response.choices[0].message.content
    except Exception as e:
        print(f"Error communicating with OpenAI: {e}")
        return None

def main():
    api_key = os.getenv('YOUTUBE_API_KEY')
    video_url = input("Enter YouTube Video URL: ").strip()
    video_id = extract_video_id(video_url)
    if not video_id:
        print("Invalid YouTube URL. Could not find video ID.")
        return
    print(f"Fetching transcript for Video ID: {video_id}...")
    transcript_text = get_transcript_text(video_id)
    if transcript_text:
        word_count = len(transcript_text.split())
        print(f"Transcript fetched successfully ({word_count} words).")
        summary = summarize_text(transcript_text[:MAX])
        if summary:
            print("\n" + '=' * 40)
            print('TRANSCRIPT SUMMARY')
            print('=' * 40 + "\n")
            print(summary)
            print("\n" + '=' * 40)

    comments = get_video_comments(video_id, api_key)
    comment_text = " ".join(comments)
    if comment_text:
        print(f"Collected {len(comments)} comments.")
        summary = summarize_text(comment_text[:MAX])
        if summary:
            print("\n" + '=' * 40)
            print('COMMENT SUMMARY')
            print('=' * 40 + "\n")
            print(summary)
            print("\n" + '=' * 40)

if __name__ == "__main__":
    main()
