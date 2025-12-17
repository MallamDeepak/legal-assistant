import csv
import os

CORPUS_PATH = 'data/legal_corpus.csv'

ipc_data = [
    # Theft
    {
        'section_id': 'IPC 378',
        'title': 'Theft defined',
        'text': 'Whoever, intending to take dishonestly any movable property out of the possession of any person without that person\'s consent, moves that property in order to such taking, is said to commit theft.',
        'source': 'IPC',
        'language': 'en'
    },
    {
        'section_id': 'IPC 379',
        'title': 'Punishment for theft',
        'text': 'Whoever commits theft shall be punished with imprisonment of either description for a term which may extend to three years, or with fine, or with both.',
        'source': 'IPC',
        'language': 'en'
    },
    # Murder
    {
        'section_id': 'IPC 300',
        'title': 'Murder',
        'text': 'Except in the cases hereinafter excepted, culpable homicide is murder, if the act by which the death is caused is done with the intention of causing death, or if it is done with the intention of causing such bodily injury as the offender knows to be likely to cause the death of the person to whom the harm is caused.',
        'source': 'IPC',
        'language': 'en'
    },
    {
        'section_id': 'IPC 302',
        'title': 'Punishment for murder',
        'text': 'Whoever commits murder shall be punished with death or imprisonment for life, and shall also be liable to fine.',
        'source': 'IPC',
        'language': 'en'
    },
    # Cheating
    {
        'section_id': 'IPC 415',
        'title': 'Cheating',
        'text': 'Whoever, by deceiving any person, fraudulently or dishonestly induces the person so deceived to deliver any property to any person, or to consent that any person shall retain any property, or intentionally induces the person so deceived to do or omit to do anything which he would not do or omit if he were not so deceived, and which act or omission causes or is likely to cause damage or harm to that person in body, mind, reputation or property, is said to "cheat".',
        'source': 'IPC',
        'language': 'en'
    },
    {
        'section_id': 'IPC 420',
        'title': 'Cheating and dishonestly inducing delivery of property',
        'text': 'Whoever cheats and thereby dishonestly induces the person deceived to deliver any property to any person, or to make, alter or destroy the whole or any part of a valuable security, or anything which is signed or sealed, and which is capable of being converted into a valuable security, shall be punished with imprisonment of either description for a term which may extend to seven years, and shall also be liable to fine.',
        'source': 'IPC',
        'language': 'en'
    },
    # Hurt
    {
        'section_id': 'IPC 323',
        'title': 'Punishment for voluntarily causing hurt',
        'text': 'Whoever, except in the case provided for by section 334, voluntarily causes hurt, shall be punished with imprisonment of either description for a term which may extend to one year, or with fine which may extend to one thousand rupees, or with both.',
        'source': 'IPC',
        'language': 'en'
    }
]

def add_ipc():
    # check if already exists
    with open(CORPUS_PATH, 'r', encoding='utf-8') as f:
        content = f.read()
        if 'IPC 379' in content:
            print("IPC data already present.")
            return

    with open(CORPUS_PATH, 'a', newline='', encoding='utf-8') as f:
        writer = csv.DictWriter(f, fieldnames=['section_id', 'title', 'text', 'source', 'language'])
        # Start writing
        for row in ipc_data:
            writer.writerow(row)
            print(f"Added {row['section_id']}")

if __name__ == '__main__':
    add_ipc()
