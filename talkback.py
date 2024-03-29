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

# Capture the audio input
with mic as source:
    print("Speak:")
    audio = r.listen(source)

# Convert the recorded audio to text
text = r.recognize_google(audio)
print("You said: " + text)

source = "output.mp3"
dest = "output.wav"

# Convert the text to speech
tts = gTTS(text, lang="en")
tts.save(source)

# Convert the mp3 to wav
sound = AudioSegment.from_mp3(source)
sound.export(dest, format="wav")

# Initialize the speaker
p = pyaudio.PyAudio()
stream = p.open(format=pyaudio.paInt16,
                channels=1,
                rate=22050,
                output=True)

# Play the generated speech output
chunk_size = 1024
file_size = os.path.getsize(dest)
with open(dest, "rb") as fh:
    while fh.tell() != file_size:
        audio_frame = fh.read(chunk_size)
        stream.write(audio_frame)

# Cleanup
stream.stop_stream()
stream.close()
p.terminate()
