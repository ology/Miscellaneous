import os
import pyaudio
import wave
import speech_recognition as sr
from gtts import gTTS
import ffmpeg
from pydub import AudioSegment

# Initialize the microphone
r = sr.Recognizer()
mic = sr.Microphone()

# Capturing the audio input
with mic as source:
    print("Speak:")
    audio = r.listen(source)

# Converting the recorded audio input to text
text = r.recognize_google(audio)
print("You said: " + text)

source = "output.mp3"
dest = "output.wav"

# Using the gTTS library to convert the text to speech
tts = gTTS(text, lang='en')
tts.save(source)

# convert wav to mp3                                                            
sound = AudioSegment.from_mp3(source)
sound.export(dest, format="wav")

# Initialize the speaker
CHUNK_SIZE = 1024
FORMAT = pyaudio.paInt16
RATE = 22050
FILE_SIZE = os.path.getsize(dest)
p = pyaudio.PyAudio()
stream = p.open(format=FORMAT,
                channels=1,
                rate=RATE,
                output=True)

# Playing the generated speech output
with open(dest, "rb") as fh:
    while fh.tell() != FILE_SIZE:
        AUDIO_FRAME = fh.read(CHUNK_SIZE)
        stream.write(AUDIO_FRAME)

# Cleanup
stream.stop_stream()
stream.close()
p.terminate()
