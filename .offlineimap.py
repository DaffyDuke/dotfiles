import os
import subprocess

def mailpasswd(acct):
    acct = os.path.basename(acct)
    path = "/home/daffy/.passwd/%s.gpg" % acct
    args = ["gpg", "--use-agent", "--quiet", "--batch", "-d", path]
    proc = subprocess.Popen(args, stdout=subprocess.PIPE)
    output = proc.communicate()[0].strip()
    retcode = proc.wait()
    if retcode == 0:
        return output
    else:
        return ''

# Take a folder name that is not 'INBOX' then:
# 1. remove prefixed 'INBOX.'
# 1. make it lowercase
# 1. split lowercased on ' '
# 1. return the first part of the split
def remote_lowered(folder):
    if folder == 'INBOX':
      return folder
    else:
      return folder.replace('INBOX.', '').lower().split(' ')[0]

# Take a folder name that is not 'INBOX' then:
# If folder in mapping.keys() return the corresponding value
# If folder not in mapping.keys() return folder with the first letter capitalized
def local_capitalized(folder, mapping={}, prefix=''):
    if folder == 'INBOX':
      return folder
    elif folder in mapping.keys():
      return mapping.get(folder)
    else:
      return prefix + folder.capitalize()

# Provide a mapping of common [Gmail] folders
def gmail_mapping():
    return {
        '[Gmail]/All Mail':   'archive',
        '[Gmail]/Drafts':     'drafts',
        '[Gmail]/Important':  'important',
        '[Gmail]/Sent Mail':  'sent',
        '[Gmail]/Starred':    'starred',
        '[Gmail]/Trash':      'trash',
        '[Gmail]/Spam':       'junk',
    }

# Offlineimap nametrans methods for gmail accounts
def gmail_remote(folder):
    mapping = gmail_mapping()
    return mapping.get(folder, folder)

def gmail_local(folder):
    m = gmail_mapping()
    mapping = dict(zip(m.values(), m.keys()))
    return mapping.get(folder, folder)

# Checks if the name of folder is one commonly used by Airmail
def is_airmail_folder(folder):
    return folder.startswith('[Airmail]')

# Checks if the name of folder is 'All'
def is_protonmail_all_folder(folder):
    return folder.endswith('All Mail')

# Offlineimap methods for fastmail.fm accounts
def fastmail_remote(folder):
    return remote_lowered(folder)

def fastmail_local(folder):
    mapping = {
        'junk':      'INBOX.Junk Mail',
        'sent':      'INBOX.Sent Items',
    }
    return local_capitalized(folder, mapping, 'INBOX.')

# Offlineimap methods for protonmail accounts
def protonmail_mapping():
    return {
        'All Mail': 'all',
        'Archive': 'archive',
        'Sent': 'sent',
        'Spam': 'spam',
        'Trash': 'trash',
    }

def protonmail_remote(folder):
    mapping = protonmail_mapping()
    return mapping.get(folder, folder)

def protonmail_local(folder):
    m = protonmail_mapping()
    mapping = dict(zip(m.values(), m.keys()))
    return mapping.get(folder, folder)

# Offlineimap methods for lynr.co accounts
# Uses `remote_lowered` but the remote mailboxes aren't preceded by 'INBOX.'
# so the translations only splits and lowercases.
def lynrco_remote(folder):
    return fastmail_remote(folder)

def lynrco_local(folder):
    return fastmail_local(folder)

# Define wrapper function for whether or not a fastmail folder should sync
def should_sync_fastmail(folder):
    return not folder == 'INBOX.Junk Mail' \
        and not folder == 'INBOX.Notes' \
        and not folder == 'INBOX.Trash' \
        and not folder.endswith('taxes-2017') \
        and not is_airmail_folder(folder)

# Define wrapper function for whether or not a siberia folder should sync
def should_sync_gmail(folder):
    return not folder == '[Gmail]/Spam' \
        and not folder == '[Gmail]/Important' \
        and not folder == '[Gmail]/Trash' \
        and not folder.startswith('freelance') \
        and not folder.startswith('lynr') \
        and not folder.startswith('persnicketly') \
        and not folder.startswith('recipes') \
        and not folder.startswith('taxes') \
        and not is_airmail_folder(folder)

# Define wrapper function for whether or not a siberia folder should sync
def should_sync_siberia(folder):
    return not folder == '[Gmail]/Spam' \
        and not folder == '[Gmail]/Important' \
        and not folder == '[Gmail]/Trash' \
        and not folder.startswith('[Readdle]') \
        and not folder.startswith('avis') \
        and not folder.startswith('billing') \
        and not folder.startswith('cloudnav') \
        and not folder.startswith('contacts') \
        and not folder.startswith('dated') \
        and not folder.startswith('intel') \
        and not is_airmail_folder(folder)
