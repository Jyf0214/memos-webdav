import os

def commit_callback(commit):
    if commit.author_name == b'eyjafjalla-volcano' and commit.committer_name == b'GitHub':
        commit.committer_name = b'eyjafjalla-volcano'
        commit.committer_email = b'236166990+eyjafjalla-volcano@users.noreply.github.com'
    return commit
