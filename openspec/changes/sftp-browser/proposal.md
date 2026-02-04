# Proposal: SFTP Browser

## Why

Users often need to transfer files to/from remote servers. An integrated SFTP
browser provides visual file navigation, download/upload with progress, and
eliminates the need to remember scp syntax.

## What Changes

- Implement SFTP client using dartssh2
- Create FileBrowser widget with directory listing
- Support navigation, file info display
- Add file download with progress indicator
- Add file upload from device picker
- Integrate with system share sheet
- Handle large file transfers efficiently

## Capabilities

### New Capabilities

- `sftp-client`: File transfer via SSH
- `file-browser`: Visual directory navigation
- `file-transfer`: Upload/download with progress

## Phase

**Phase 2 - Intelligence** (Months 5-7)

## Priority

**P1 - Should Have**
