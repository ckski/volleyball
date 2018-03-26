# Installation:
#
# Use Python 3
# $ pip install beautifulsoup4
# $ pip install requests


# User's guide

# Team id is per season/year. Each year there is a new id given for each team.
# These can be scraped from the team page under the options selector.
# 

# Data model:

# game_data :: { 'id': string, 'source': string, 'date': ISO8601 string, 'sets': {1: set, 2: set, 3: set [, 4: set [, 5: set]]}}
# set :: {'starters': {team_name: list(player_name)}, 'events': list(event)}
# event :: {'server': player_name, 'point': team_name, 'event': event_body} | {'point': team_name, 'event': list('OFFICIAL_AWARDED')}
# event_body :: list('KILL', by player_name [, from player_name [, block error by]])
#				| list('ATTACK_ERROR', by player_name [, list(blocker player name)])
#				| list('BLOCK_ERROR', by player_name)
#				| list('SERVICE_ERROR')
#				| list('SERVICE_ACE', receiver player_name | 'TEAM')
#				| list('BAD_SET', by player_name)    // Bad set by
#				| list('BHE', by player_name)		  // ball handling error
#				| list('TIMEOUT', opaque())
#				| list('SUB', opaque())
#				| list('YELLOW_CARD', by team_name, player_name, point)
#				| list('ILLEGAL_SUB', by team_name, [player_name, player_name], point)
# 

from bs4 import BeautifulSoup   # For scraping
import logging					
import requests					# For http get requests
from urllib.parse import urlparse  # For parsing the url
from urllib.parse import parse_qs	# For parsing query string
import os 						# For os.path for parsing urls
import re
import json						# For output files
import datetime					# For parsing date into ISO8601
import time 					# for sleep

# CONFIGURATION

scraper_cache_directory = 'scraper_cache/'
stats_ncaa_cache_file = 'scraper_cache/stats_ncaa_cache.json'
game_data_directory = 'game_data/'

# create logger
logger = logging.getLogger('scraper')
logger.setLevel(logging.DEBUG)

# create console handler and set level to debug
ch = logging.StreamHandler()
ch.setLevel(logging.DEBUG)

# create formatter
# formatter = logging.Formatter('%(asctime)s - %(levelname)s - %(message)s')
formatter = logging.Formatter('%(levelname)s - %(message)s')

# add formatter to ch
ch.setFormatter(formatter)

# add ch to logger
logger.addHandler(ch)


url = "http://stats.ncaa.org/game/play_by_play/3979157"

def main():

	stats_ncaa_cache = { }


	def init():
		nonlocal stats_ncaa_cache
		# Initializes cached data.

		if os.path.isfile(stats_ncaa_cache_file):
			logger.info("Loading cache for stats.ncaa.org")
			with open(stats_ncaa_cache_file) as f:
				contents = f.read()
				if contents != '':
					stats_ncaa_cache = json.loads(contents)
		else:
			logger.info("No cache found for stats.ncaa.org")


	def update_cache():
		with open(stats_ncaa_cache_file, 'w') as f:
			f.write(json.dumps(stats_ncaa_cache))


	def save_game_data(data):
		((team_1_id, team_1_name), (team_2_id, team_2_name)) = data['teams']
		team_1_name = team_1_name.replace('.', '')
		team_2_name = team_2_name.replace('.', '')
		date = data['date']
		title = '%s %s vs %s' % (date, team_1_name, team_2_name)
		
		dir_path = game_data_directory + data['source'] + '/'
		full_path = dir_path + title + '.json'

		if not os.path.exists(dir_path):
			os.makedirs(dir_path)

		logger.info("Saving %s to %s" % (data['id'], full_path))

		with open(full_path, 'w') as f:
			f.write(json.dumps(data))

	def save_box_score(data):
		m = re.search(r"\/([^/]*)$", data['id'])
		base_id = m.group(1)
		dir_path = game_data_directory + data['source'] + '/boxscore/'
		full_path = dir_path + base_id + '.json'

		if not os.path.exists(dir_path):
			os.makedirs(dir_path)

		logger.info("Saving boxscore for %s to %s" % (data['id'], full_path))

		with open(full_path, 'w') as f:
			f.write(json.dumps(data))


	def fetch_team(url):
		logger.info("HTTP GET: " + url)

		r = urlparse(url)
		web_host = r.netloc

		if web_host == 'stats.ncaa.org':
			team_id = web_host + '/teams/' + os.path.basename(r.path)
			title = '%s_teams_%s.html' % (web_host, os.path.basename(r.path))
		elif web_host == 'canadawest.org':
			base_id = parse_qs(r.query)['teamId'][0]
			team_id = web_host + ':' + 'team/' + base_id
			title = '%s_team_%s' % (web_host, base_id)
		else:
			raise Exception('Unknown webhost')

		r = requests.get(url)
		if r.status_code == 200:
			html_file_path = scraper_cache_directory + title
			logger.info("Successfully retrieved team data, saving to: " + html_file_path)
			with open(html_file_path, 'w') as f: f.write(r.text)
			
			return parse_team(html_file_path, web_host, team_id)

		else:
			logger.error("Failed retrieving team data")


	def parse_team(file, web_host, team_id):
		logger.info("Parsing %s" % (team_id))
		with open(file) as f: soup = BeautifulSoup(f, "html.parser")
		if web_host == 'stats.ncaa.org':
			game_ids = []
			last_row = len(soup('table')[1]('tr'))
			for i in range(2, last_row):
				game_url = soup('table')[1]('tr')[i]('td')[2].a.attrs['href']
				r = urlparse(game_url)
				game_id = web_host + '/game/' + os.path.basename(r.path)
				game_ids.append(game_id)

			logger.debug("Team " + team_id + " played games: " + str(game_ids))

			return {'id': team_id, 'web_host': web_host, 'games': game_ids}

		elif web_host == 'canadawest.org':
			# game_ids = []
			game_ids = list(map(lambda tag: tag.attrs['href'], soup('table')[3]('a', string='Box Score')))

			logger.debug("Team " + team_id + " played games: " + str(game_ids))

			return {'id': team_id, 'web_host': web_host, 'games': game_ids}

		else:
			logger.error("Unknown host for parsing team: " + web_host)



	def fetch_play_by_play(url):
		# title = "2016-01-08 Stanford vs Ball St"

		logger.info("HTTP GET: " + url)

		r = urlparse(url)
		web_host = r.netloc   # e.g. http://stats.ncaa.org/game/play_by_play/3979157 => stats.ncaa.org
		
		if web_host == 'stats.ncaa.org':
			game_id = web_host + '/game/' + os.path.basename(r.path)  # e.g. http://stats.ncaa.org/game/play_by_play/3979157 => stats.ncaa.org/game/3979157
			title = '%s_game_%s.html' % (web_host, os.path.basename(r.path))
		elif web_host == 'canadawest.org':
			m = re.search(r"^(.*?)\.xml$", os.path.basename(r.path))
			base_id = m.group(1)
			game_id = web_host + ':game/' + base_id
			# e.g. http://canadawest.org/sports/mvball/2017-18/boxscores/20180112_aj4q.xml?view=plays => canadawest.org:game/20180112_aj4q
			title = '%s_game_%s.html' % (web_host, base_id)
		else:
			raise Exception('Unknown web host')

		r = requests.get(url)
		if r.status_code == 200:
			html_file_path = scraper_cache_directory + title
			logger.info("Successfully retrieved play by play, saving to: " + html_file_path)
			with open(html_file_path, 'w') as f: f.write(r.text)

			return parse_play_by_play(html_file_path, web_host, game_id)

		else:
			logger.error("Failed retrieving play by play resource")

	# web_host :: 'stats.ncaa.org' | 'canadawest.org'
	def parse_play_by_play(file, web_host, game_id):
		# soup = BeautifulSoup(contents, "html.parser")
		logger.info("Parsing %s" % (game_id))
		with open(file) as f: soup = BeautifulSoup(f, "html.parser")

		if web_host == 'stats.ncaa.org':
			tables = soup('table')
		
			game_data = {'source': web_host, 'id': game_id}

			# First parsing the team names and ids.

			def parse_team_id_name(node):
				if not node.a:
					logger.warn('Missing link for team name, so no team id available')
					return ('MISSING', str(node.string))

				href = node.a.attrs['href']

				if href in stats_ncaa_cache:
					team_id = web_host + "/" + os.path.basename(stats_ncaa_cache[href])
				else:
					url = "http://" + web_host + href
					logger.info("HTTP GET: " + url)
					r = requests.get(url, allow_redirects=False)
					if r.status_code != 302: logger.error("Expected redirect on url: " + url)
					
					stats_ncaa_cache[href] = r.headers['Location']
					update_cache()

					team_id = web_host + "/" + os.path.basename(r.headers['Location'])
					
				return (team_id, str(node.string))



			team_1 = parse_team_id_name(tables[0]("tr")[1].td)
			team_2 = parse_team_id_name(tables[0]("tr")[2].td)

			game_data['teams'] = (team_1, team_2)

			# Parsing date
			date = tables[3].tr('td')[1].string
			date = datetime.datetime.strptime(date, '%m/%d/%Y')
			date = date.strftime('%Y-%m-%d')

			game_data['date'] = date

			# Parsing each set.

			set_count = len(tables[6]('a'))

			def parse_set_plays(node, team_1, team_2):
				set_data = {'starters': {}}

				# set_data :: {'starters': {team_name: [player_name * 6, libero_player_name]} }

				# (team_1_id, team_1_name) = team_1
				# (team_2_id, team_2_name) = team_2

				# def team_name_to_id(name):
				# 	if name == team_1_name: return team_1_id
				# 	if name == team_2_name: return team_2_id
				# 	raise Exception("Invalid name: " + name + " expected " + team_1_name + " or " + team_2_name)

				# logger.debug("Parsing set")
				# starters_1 = node('tr')[1]('td')[1].string
				# starters_2 = node('tr')[2]('td')[1].string

				def parse_starters(starters_string):
					nonlocal set_data
					# logger.debug("Parse starters: " + starters_string)
					m_1 = re.search(r"(.*?) starters: (.*?)\.$", starters_string)
					team_name = m_1.group(1)
					# team_id = team_name_to_id(m_1.group(1))

					starters = list(map(lambda s: s.strip(), m_1.group(2).split(";")))
					starters[-1] = starters[-1].replace('libero ', '')

					set_data['starters'][team_name] = starters

				parse_starters(str(node('tr')[1]('td')[1].string))
				parse_starters(str(node('tr')[2]('td')[1].string))


				# Parse each action

				def parse_action(action_string):
					# logger.debug("Parsing action: " + s)
					
					if action_string.startswith('Timeout'):
						# TODO: parse action_string
						return ('TIMEOUT', action_string)

					if action_string.startswith('Point'):
						m = re.search(r"^Point ([^:]*):\s*\(([^)]*)\) (.*?)\.$", action_string)

						if not m: 
							if 'awarded by official' in action_string:
								m = re.search(r"^Point ([^:]*):", action_string)
								if m: return {'point': m.group(1), 'event': ('OFFICIAL_AWARDED',)}
							
							raise Exception("Error parsing action string: " + action_string)

						point_to = m.group(1)
						server = m.group(2)
						event = m.group(3)

						if event.startswith('Kill'):
							m = re.search(r"Kill by (.*?) \(from ([^)]*)\), block error by (.*)$", event)
							if m: return {'point': point_to, 'server': server, 'event': ('KILL', m.group(1), m.group(2), m.group(3))}

							m = re.search(r"^Kill by (.*?) \(from ([^)]*)\)$", event)
							if m: return {'point': point_to, 'server': server, 'event': ('KILL', m.group(1), m.group(2))}

							m = re.search(r"Kill by, block error by (.*)$", event)
							if m: return {'point': point_to, 'server': server, 'event': ('BLOCK_ERROR', m.group(1))}

							m = re.search(r"^Kill by (.*)$", event)
							if m: return {'point': point_to, 'server': server, 'event': ('KILL', m.group(1))}
							
							if not m: raise Exception("Error parsing kill: " + action_string)

						if event.startswith('Attack error'):
							m = re.search(r"^Attack error by (.*?) \(block by ([^)]*)\)$", event)
							if m: return {'point': point_to, 'server': server, 'event': ('ATTACK_ERROR', m.group(1), list(map(lambda s: s.strip(), m.group(2).split(";"))))}

							m = re.search(r"^Attack error by (.*?)$", event)
							if not m: raise Exception("Error parsing attack error: " + action_string)
							return {'point': point_to, 'server': server, 'event': ('ATTACK_ERROR', m.group(1))}

						if event.startswith('Service error'):
							return {'point': point_to, 'server': server, 'event': ('SERVICE_ERROR',)}

						if event.startswith('Service ace'):
							m = re.search(r"^Service ace \(([^)]*)\)$", event)
							if not m: raise Exception("Error parsing service ace: " + action_string)
							return {'point': point_to, 'server': server, 'event': ('SERVICE_ACE', m.group(1))}


						if event.startswith('Bad set'):
							m = re.search(r"^Bad set by (.*)$", event)
							if not m: raise Exception("Error parsing bad set: " + action_string)
							return {'point': point_to, 'server': server, 'event': ('BAD_SET', m.group(1))}

						if event.startswith('Ball handling error'):
							m = re.search(r"^Ball handling error by (.*)$", event)
							if not m: raise Exception("Error parsing ball handling error: " + action_string)
							return {'point': point_to, 'server': server, 'event': ('BHE', m.group(1))}


						raise Exception('Error parsing event: ' + action_string)
						# TODO: ball handling error 
						# if event.startswith('Attack error'):

						# logger.debug("point_to: %s, server: %s, event: %s" % (point_to, server, event))
						return ('_', '_')

					if 'subs:' in action_string:
						# TODO: parse action_string
						return ('SUB', action_string)

					if 'yellow card' in action_string.lower() or 'yellowcard' in action_string.lower():
						logger.warn('Yellow card encountered, need to edit to add if point was awarded')
						return ('YELLOW_CARD', '???', action_string)

					if 'illegal substitution' in action_string.lower():
						logger.warn('Illegal substituion encountered, need to edit to add if point was awarded')
						return ('ILLEGAL_SUB', '???', action_string)

					if action_string.startswith('Triple block'):
						return None

					if 'starters:' in action_string:
						logger.warn('Bad format found for starters: ' + action_string)
						return None

					if 'delay of game warning' in action_string.lower():
						return None

					raise Exception("Unknown action string: " + action_string)

				actions = []
				i = 3
				while True:
					# Loop until reach a row that has only one cell in it (i.e. End of xth set row)
					row = node('tr')[i]('td')
					if len(row) < 2: break

					s = str(row[1].string)
					action = parse_action(s)
					if action:
						actions.append(action)
					# else:
						# logger.warn("Bad data found at row %d" % (i))
					# logger.debug(action)

					i += 1

				set_data['events'] = actions
				# for i in range(node('tr')[3]('td')[1].string)
				# soup('table')[7]('tr')[3]('td')[1].string
				# logger.debug("starters 1: " + starters_1)
				# logger.debug("starters 2: " + starters_2)

				# logger.debug(set_data)

				return set_data


			# logger.debug(team_1)
			# logger.debug(team_2)

			sets = {}
			for i in range(1, set_count+1):
				sets[i] = parse_set_plays(tables[5+i*2], team_1, team_2)

			game_data['sets'] = sets

			return game_data

			# logger.debug(game_data)

		elif web_host == 'canadawest.org':
			# logger.debug('Parsing canadawest play by play')
			
			game_data = {'source': web_host, 'id': game_id}

			# First parsing the team names and ids.

			def parse_team_id_name(node):
				href = node.attrs['href']
				r = urlparse(href)
				base_id = parse_qs(r.query)['id'][0]
				team_id = web_host + ":team/" + base_id
				return (team_id, str(node.string).strip())

			team_1 = parse_team_id_name(soup.table.select('td a')[0])
			team_2 = parse_team_id_name(soup.table.select('td a')[1])

			# logger.debug('teams: ' + str(team_1) + ' ' + str(team_2))

			game_data['teams'] = (team_1, team_2)

			# Parsing date
			date = soup.main('div')[2].contents[6]
			m = re.search(r"^([^\n]*)\n", date)
			date = m.group(1)
			date = datetime.datetime.strptime(date, '%m/%d/%Y')
			date = date.strftime('%Y-%m-%d')

			# logger.debug("date is: " + str(date))

			game_data['date'] = date


			def parse_starters(starters_string, set_data):
				# logger.debug("Parse starters: " + starters_string)
				m_1 = re.search(r"(.*?) starters: (.*?)\.$", starters_string)
				team_name = m_1.group(1)
				# # team_id = team_name_to_id(m_1.group(1))

				starters = list(map(lambda s: s.strip(), m_1.group(2).split(";")))
				starters[-1] = starters[-1].replace('libero ', '')
				set_data['starters'][team_name] = starters


			def parse_action(action_string):
				# logger.debug("Parsing action: " + action_string)
				
				if action_string.startswith('Timeout'):
					# TODO: parse action_string
					return ('TIMEOUT', action_string)
				
				m = re.search(r"^.*Point (.*)$", action_string)

				if m:
					point_to = m.group(1)

					m = re.search(r"^\[(.*?)\] (.*)\. Point", action_string)

					if not m: 
						if 'awarded by official' in action_string:
							# m = re.search(r"^Point ([^:]*):", action_string)
							# if m: return {'point': m.group(1), 'event': ('OFFICIAL_AWARDED',)}
							return {'point': point_to, 'event': ('OFFICIAL_AWARDED',)}

						raise Exception("Error parsing action string: " + action_string)

					# point_to = m.group(1)
					server = m.group(1)
					event = m.group(2)

					if event.startswith('Kill'):
						m = re.search(r"Kill by (.*?) \(from ([^)]*)\), block error by (.*)$", event)
						if m: return {'point': point_to, 'server': server, 'event': ('KILL', m.group(1), m.group(2), m.group(3))}

						m = re.search(r"^Kill by (.*?) \(from ([^)]*)\)$", event)
						if m: return {'point': point_to, 'server': server, 'event': ('KILL', m.group(1), m.group(2))}

						m = re.search(r"Kill by, block error by (.*)$", event)
						if m: return {'point': point_to, 'server': server, 'event': ('BLOCK_ERROR', m.group(1))}

						m = re.search(r"^Kill by (.*)$", event)
						if m: return {'point': point_to, 'server': server, 'event': ('KILL', m.group(1))}
						
						if not m: raise Exception("Error parsing kill: " + action_string)

					if event.startswith('Attack error'):
						m = re.search(r"^Attack error by (.*?) \(block by ([^)]*)\)$", event)
						if m: return {'point': point_to, 'server': server, 'event': ('ATTACK_ERROR', m.group(1), list(map(lambda s: s.strip(), m.group(2).split(";"))))}

						m = re.search(r"^Attack error by (.*?)$", event)
						if not m: raise Exception("Error parsing attack error: " + action_string)
						return {'point': point_to, 'server': server, 'event': ('ATTACK_ERROR', m.group(1))}

					if event.startswith('Service error'):
						return {'point': point_to, 'server': server, 'event': ('SERVICE_ERROR',)}

					if event.startswith('Service ace'):
						m = re.search(r"^Service ace \(([^)]*)\)$", event)
						if not m: raise Exception("Error parsing service ace: " + action_string)
						return {'point': point_to, 'server': server, 'event': ('SERVICE_ACE', m.group(1))}

					if event == 'Service ':
						logger.warn('Missing data for service event')
						return {'point': point_to, 'server': server, 'event': 'MISSING'}

					if event.startswith('Bad set'):
						m = re.search(r"^Bad set by (.*)$", event)
						if not m: raise Exception("Error parsing bad set: " + action_string)
						return {'point': point_to, 'server': server, 'event': ('BAD_SET', m.group(1))}

					if event.startswith('Ball handling error'):
						m = re.search(r"^Ball handling error by (.*)$", event)
						if not m: raise Exception("Error parsing ball handling error: " + action_string)
						return {'point': point_to, 'server': server, 'event': ('BHE', m.group(1))}


					raise Exception('Error parsing event: ' + action_string)
					# TODO: ball handling error 
					# if event.startswith('Attack error'):

					# logger.debug("point_to: %s, server: %s, event: %s" % (point_to, server, event))
					return ('_', '_')

				if 'subs:' in action_string:
					# TODO: parse action_string
					return ('SUB', action_string)

				if 'yellow card' in action_string.lower() or 'yellowcard' in action_string.lower():
					logger.warn('Yellow card encountered, need to edit to add if point was awarded')
					return ('YELLOW_CARD', '???', action_string)

				if 'illegal substitution' in action_string.lower():
					logger.warn('Illegal substituion encountered, need to edit to add if point was awarded')
					return ('ILLEGAL_SUB', '???', action_string)

				# if action_string.startswith('Triple block'):
				# 	return None

				if 'starters:' in action_string:
					logger.warn('Bad format found for starters: ' + action_string)
					return None

				# if 'delay of game warning' in action_string.lower():
				# 	return None
				logger.warn("Unknown action string: " + action_string)
				return None


			# Parsing each set.
			sets = {}
			set_i = 0
			rows = soup('table')[2]('tr')

			for row in rows[1:]:
				if row.select('th[id]') != []:
					set_i += 1
					sets[set_i] = {'events': [], 'starters': {}}
					continue

				if row.string == 'back to top':
					continue

				row_str = str(row('td')[1].string).strip()

				if 'starters' in row_str:
					parse_starters(row_str, sets[set_i])

				else:
					action = parse_action(row_str)
					if action:
						sets[set_i]['events'].append(action)


			game_data['sets'] = sets

			return game_data


		else:
			logger.error('Unknown web host: ' + web_host)
		


	def fetch_box_score(url):
		# title = "2016-01-08 Stanford vs Ball St"

		logger.info("HTTP GET: " + url)

		r = urlparse(url)
		web_host = r.netloc   # e.g. http://stats.ncaa.org/game/play_by_play/3979157 => stats.ncaa.org
		
		if web_host == 'stats.ncaa.org':
			raise Exception('unimplemented')
			# game_id = web_host + '/game/' + os.path.basename(r.path)  # e.g. http://stats.ncaa.org/game/play_by_play/3979157 => stats.ncaa.org/game/3979157
			# title = '%s_game_%s.html' % (web_host, os.path.basename(r.path))
		elif web_host == 'canadawest.org':
			m = re.search(r"^(.*?)\.xml$", os.path.basename(r.path))
			base_id = m.group(1)
			game_id = web_host + ':game/' + base_id
			# e.g. http://canadawest.org/sports/mvball/2017-18/boxscores/20180112_aj4q.xml?view=plays => canadawest.org:game/20180112_aj4q
			title = '%s_game_boxscore_%s.html' % (web_host, base_id)
		else:
			raise Exception('Unknown web host')

		r = requests.get(url)
		if r.status_code == 200:
			html_file_path = scraper_cache_directory + title
			logger.info("Successfully retrieved play by play, saving to: " + html_file_path)
			with open(html_file_path, 'w') as f: f.write(r.text)

			return parse_box_score(html_file_path, web_host, game_id)

		else:
			logger.error("Failed retrieving play by play resource")


	def parse_box_score(file, web_host, game_id):
		# soup = BeautifulSoup(contents, "html.parser")
		logger.info("Parsing boxscore for %s" % (game_id))
		with open(file) as f: soup = BeautifulSoup(f, "html.parser")

		if web_host == 'canadawest.org':
			tables = soup('table')
			box_score_data = {'source': web_host, 'id': game_id}

			def parse_player(node):
				href = node.attrs['href']
				r = urlparse(href)
				base_id = parse_qs(r.query)['id'][0]
				player_id = web_host + ":player/" + base_id

				# TODO: add player number !

				ta_stat = int(node.parent.parent('td')[5].string)
				digs = int(node.parent.parent('td')[11].string)

				return (player_id, str(node.string).strip(), {"TA": ta_stat, "DIGS": digs})	

			team_1_name = str(soup('table')[4]('tr')[0].h4.string).strip()
			team_1_players = list(map(parse_player, soup('table')[4].select('tr a')))

			team_2_name = str(soup('table')[5]('tr')[0].h4.string).strip()
			team_2_players = list(map(parse_player, soup('table')[5].select('tr a')))

			box_score_data['teams'] = {}
			box_score_data['teams'][team_1_name] = team_1_players
			box_score_data['teams'][team_2_name] = team_2_players

			def parse_per_set_ta(node, team_name):
				if node.tr.h4.string != team_name: raise Exception("Team name does not match expected")
				return list(map(lambda n: int(n('td')[3].string), node('tr')[2:]))

			team_1_per_set_ta = parse_per_set_ta(soup('table')[2], team_1_name)
			team_2_per_set_ta = parse_per_set_ta(soup('table')[3], team_2_name)

			box_score_data['ta_per_set'] = {}
			box_score_data['ta_per_set'][team_1_name] = team_1_per_set_ta
			box_score_data['ta_per_set'][team_2_name] = team_2_per_set_ta


			# logger.info(box_score_data)

			return box_score_data

		else:
			raise Exception("Unknown web host")

	# fetch_play_by_play(url)

	init()

	# canadawest_games = [
	# 	# "20161028_9sk3",
	# 	"20161029_u4om",
	# 	"20161104_xwo6",
	# 	"20161105_wy5c",
	# 	"20161118_146o",
	# 	"20161119_s2n8",
	# 	"20161125_2zth",
	# 	"20161126_fn7z",
	# 	"20161202_ols6",
	# 	"20161203_109e",
	# 	"20170106_osv4",
	# 	"20170107_i6ao",
	# 	"20170113_c8x5",
	# 	"20170114_kj1t",
	# 	"20170120_gq4t",
	# 	"20170121_pnkm",
	# 	"20170127_74or",
	# 	"20170128_oy4e",
	# 	"20170203_chcs",
	# 	"20170204_h4kp",
	# 	"20170217_73f1",
	# 	"20170218_psc7",
	# 	"20170224_ya31",
	# 	"20170225_0gcc"]

	# for game_id in canadawest_games:
	# 	boxscore = fetch_box_score('http://canadawest.org/sports/mvball/2016-17/boxscores/' + game_id + '.xml')
	# 	save_box_score(boxscore)

	# box_score = fetch_box_score('http://canadawest.org/sports/mvball/2016-17/boxscores/20161028_9sk3.xml')
	# save_box_score(box_score)

	# file = scraper_cache_directory + "2016-01-08 Stanford vs Ball St" + ".html"
	# test = 'scraper_cache/2016-01-08 Stanford vs Ball St.html'
	# game_data = parse_play_by_play(file, 'stats.ncaa.org', '3979157')
	# file = scraper_cache_directory + 'stats.ncaa.org_game_4002780.html'
	# game_data = parse_play_by_play(file, 'stats.ncaa.org', '4002780')
	# game_data = fetch_play_by_play("http://stats.ncaa.org/game/play_by_play/3979157")
	# logger.debug(game_data)
	# save_game_data(game_data)






	# fetch_team('http://stats.ncaa.org/teams/24312') # Stanford 2015-16
	# team_data = fetch_team('http://stats.ncaa.org/teams/98971') # Stanford 2011-12
	# team_data = fetch_team('http://stats.ncaa.org/teams/79751') # Stanford 2012-13
	# team_data = fetch_team('http://stats.ncaa.org/teams/79997') # Stanford 2013-14
	# team_data = fetch_team('http://stats.ncaa.org/teams/105832') # Stanford 2014-15
	# team_data = fetch_team('http://stats.ncaa.org/teams/43636') # Stanford 2016-17

	# team_data = fetch_team('http://canadawest.org/sports/mvball/2016-17/schedule?teamId=dtjw1qxi3rsm18q9') # TWU
	# team_data = fetch_team('http://canadawest.org/sports/mvball/2016-17/schedule?teamId=8ym66afwr3tnrhwn') # UBC
	# team_data = fetch_team('http://canadawest.org/sports/mvball/2016-17/schedule?teamId=w41s4fuy1ldg73vw') # TRU
	# team_data = fetch_team('http://canadawest.org/sports/mvball/2016-17/schedule?teamId=c7d4uvmky7mmw7kx') # AB
	# team_data = fetch_team('http://canadawest.org/sports/mvball/2016-17/schedule?teamId=afgkow4zpogyvpag') # Macewan
	# team_data = fetch_team('http://canadawest.org/sports/mvball/2016-17/schedule?teamId=92rw9okcosb0aabi') # Winnepeg
	# team_data = fetch_team('http://canadawest.org/sports/mvball/2016-17/schedule?teamId=zgpxqu3xsum5vee5') # Calgary
	# team_data = fetch_team('http://canadawest.org/sports/mvball/2016-17/schedule?teamId=ismg6mi3ytuao2qw') # Brandon
	# team_data = fetch_team('http://canadawest.org/sports/mvball/2016-17/schedule?teamId=vw3suzwumcai6jjw') # Sask
	# team_data = fetch_team('http://canadawest.org/sports/mvball/2016-17/schedule?teamId=z78yo6jcwew4e0xb') # Regina
	# team_data = fetch_team('http://canadawest.org/sports/mvball/2016-17/schedule?teamId=dxr6cxddzdwobqa5') # UBCO
	# team_data = fetch_team('http://canadawest.org/sports/mvball/2016-17/schedule?teamId=m4t2yy12xffoq7f6') # MRU
	team_data = fetch_team('http://canadawest.org/sports/mvball/2016-17/schedule?teamId=ijdtf6y9xus4vfqp') # MRU

	# Manitoba ijdtf6y9xus4vfqp


	# logger.info(team_data)


	# if team_data['web_host'] == 'canadawest.org':
	game_ids = team_data['games']

	# game_ids = ['/sports/mvball/2016-17/boxscores/20170218_o40c.xml', '/sports/mvball/2016-17/boxscores/20170224_2ayj.xml', '/sports/mvball/2016-17/boxscores/20170225_qk12.xml']

	# game_ids = ['/sports/mvball/2016-17/boxscores/20170218_o40c.xml', '/sports/mvball/2016-17/boxscores/20170224_w6w6.xml', '/sports/mvball/2016-17/boxscores/20170225_8pgg.xml']
	# game_ids = ['/sports/mvball/2016-17/boxscores/20161203_ggum.xml', '/sports/mvball/2016-17/boxscores/20170106_qanm.xml', '/sports/mvball/2016-17/boxscores/20170107_72ya.xml', '/sports/mvball/2016-17/boxscores/20170113_zb4u.xml', '/sports/mvball/2016-17/boxscores/20170114_ros1.xml', '/sports/mvball/2016-17/boxscores/20170120_kr9o.xml', '/sports/mvball/2016-17/boxscores/20170121_1dz9.xml', '/sports/mvball/2016-17/boxscores/20170127_fmir.xml', '/sports/mvball/2016-17/boxscores/20170128_qcyt.xml', '/sports/mvball/2016-17/boxscores/20170210_kkto.xml', '/sports/mvball/2016-17/boxscores/20170211_a7d2.xml', '/sports/mvball/2016-17/boxscores/20170217_gz3s.xml', '/sports/mvball/2016-17/boxscores/20170218_gy6e.xml', '/sports/mvball/2016-17/boxscores/20170224_rm1i.xml', '/sports/mvball/2016-17/boxscores/20170225_v6du.xml']

	for game_id in game_ids:
		time.sleep(1)
		base_id = os.path.basename(game_id)

		game_data = fetch_play_by_play('http://canadawest.org' + game_id + '?view=plays')
		save_game_data(game_data)

		boxscore = fetch_box_score('http://canadawest.org/' + game_id)
		# boxscore = fetch_box_score('http://canadawest.org/sports/mvball/2016-17/boxscores/' + base_id + '.xml')
		save_box_score(boxscore)	



	# if team_data['web_host'] = 'canadawest.org':
	# 	game_ids = team_data['games']

	# 	for game_id in game_ids:
	# 		time.sleep(1)
	# 		# base_id = os.path.basename(game_id)
	# 		game_data = fetch_play_by_play('http://canadawest.org' + game_id + '?view=plays')
	# 		save_game_data(game_data)

	# game_ids = ['/sports/mvball/2016-17/boxscores/20170121_pnkm.xml', '/sports/mvball/2016-17/boxscores/20170127_74or.xml', '/sports/mvball/2016-17/boxscores/20170128_oy4e.xml', '/sports/mvball/2016-17/boxscores/20170203_chcs.xml', '/sports/mvball/2016-17/boxscores/20170204_h4kp.xml', '/sports/mvball/2016-17/boxscores/20170217_73f1.xml', '/sports/mvball/2016-17/boxscores/20170218_psc7.xml', '/sports/mvball/2016-17/boxscores/20170224_ya31.xml', '/sports/mvball/2016-17/boxscores/20170225_0gcc.xml']

	# # game_ids = ['/sports/mvball/2016-17/boxscores/20161029_u4om.xml']
	# for game_id in game_ids:
	# 	time.sleep(1)
	# 	game_data = fetch_play_by_play('http://canadawest.org' + game_id + '?view=plays')
	# 	save_game_data(game_data)

	# game_data = parse_play_by_play('scraper_cache/canadawest.org_game_20161028_9sk3.html', 'canadawest.org', 'canadawest.org:game/20161028_9sk3')
	# save_game_data(game_data)

	# game_ids = team_data['games']
	# logger.info("Pulling data for: " + str(game_ids))

	# parse_team('scraper_cache/stats.ncaa.org_teams_24312.html', 'stats.ncaa.org', 'stats.ncaa.org/teams/24312')

	# game_ids = ['stats.ncaa.org/game/4086248', 'stats.ncaa.org/game/4090568', 'stats.ncaa.org/game/4097620', 'stats.ncaa.org/game/4100431', 'stats.ncaa.org/game/4112165']
	# game_ids = ['stats.ncaa.org/game/734059', 'stats.ncaa.org/game/734093', 'stats.ncaa.org/game/734274', 'stats.ncaa.org/game/734195', 'stats.ncaa.org/game/734173', 'stats.ncaa.org/game/734151', 'stats.ncaa.org/game/734135', 'stats.ncaa.org/game/734120', 'stats.ncaa.org/game/734102', 'stats.ncaa.org/game/738652', 'stats.ncaa.org/game/741450', 'stats.ncaa.org/game/755653', 'stats.ncaa.org/game/758622', 'stats.ncaa.org/game/781508', 'stats.ncaa.org/game/784691', 'stats.ncaa.org/game/823395', 'stats.ncaa.org/game/828030', 'stats.ncaa.org/game/855610', 'stats.ncaa.org/game/861832', 'stats.ncaa.org/game/955994', 'stats.ncaa.org/game/957711', 'stats.ncaa.org/game/966510', 'stats.ncaa.org/game/972332', 'stats.ncaa.org/game/973752', 'stats.ncaa.org/game/988158', 'stats.ncaa.org/game/989592', 'stats.ncaa.org/game/1002217', 'stats.ncaa.org/game/1010952', 'stats.ncaa.org/game/1012776']
	
	# game_ids = ['stats.ncaa.org/game/1801592', 'stats.ncaa.org/game/1862092', 'stats.ncaa.org/game/1876212', 'stats.ncaa.org/game/1988513', 'stats.ncaa.org/game/1990418', 'stats.ncaa.org/game/1998734', 'stats.ncaa.org/game/2017133', 'stats.ncaa.org/game/2024875', 'stats.ncaa.org/game/2048155', 'stats.ncaa.org/game/2050133', 'stats.ncaa.org/game/2076826']

	# game_ids = ['stats.ncaa.org/game/4290439', 'stats.ncaa.org/game/4294668', 'stats.ncaa.org/game/4297271', 'stats.ncaa.org/game/4298450', 'stats.ncaa.org/game/4307700', 'stats.ncaa.org/game/4307044', 'stats.ncaa.org/game/4314650', 'stats.ncaa.org/game/4316096', 'stats.ncaa.org/game/4323922', 'stats.ncaa.org/game/4335908', 'stats.ncaa.org/game/4337557', 'stats.ncaa.org/game/4342815', 'stats.ncaa.org/game/4344747', 'stats.ncaa.org/game/4353146']
	# for game_id in game_ids:
		# time.sleep(1)
	# 	base_id = os.path.basename(game_id)
	# 	game_data = fetch_play_by_play('http://stats.ncaa.org/game/play_by_play/' + base_id)
	# 	save_game_data(game_data)

	# Re-parsing:
	# game_files = ['stats.ncaa.org_game_1002217.html',]
	# for game_file in game_files:
	# 	m = re.search(r"_game_(.*)\.html", game_file)
	# 	game_data = parse_play_by_play('scraper_cache/' + game_file, 'stats.ncaa.org', 'stats.ncaa.org/game/' + m.group(1))
	# 	save_game_data(game_data)

main()