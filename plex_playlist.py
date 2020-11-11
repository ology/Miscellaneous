import re

from plexapi.server import PlexServer

baseurl = 'http://plex.example.com:32400'
token = 'abcdefghijklmnopqrstuvwxyz'

plex = PlexServer(baseurl, token)

playlist_title = 'Treehouse of Horror'

for playlist in plex.playlists():
    if playlist.title == playlist_title:
        playlist.delete()
        print('{} already exists. Deleting. Will rebuild.'.format(playlist_title))

tv_shows = plex.library.section(title='TV Shows')

episode_list = []

for show in tv_shows.all():
    match = re.search(r'Simpsons', show.title)
    if match is not None:
        print(show.title + ':')
        for episode in show.episodes():
            match = re.search(r'Treehouse', episode.title)
            if match is not None:
                print("\t", episode.title)
                episode_list += episode

print('Adding {} to playlist {}.'.format(len(episode_list), playlist_title))
playlist = plex.createPlaylist(playlist_title, episode_list)

#xplex = plex.myPlexAccount()
#u = xplex.users()
#for i in u:
#    print(i)

playlist.copyToUser('john@example.com')
