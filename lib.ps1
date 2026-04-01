param(
	[string]$GitFolder = "$PSScriptRoot\..\platform-master2\git",
	[string]$GhUsername = "fedejeanne",
	[string]$RemoteName = "origin",
	[string]$UserRemoteName
)

if (-not $PSBoundParameters.ContainsKey('UserRemoteName')) {
	$UserRemoteName = $GhUsername
}

Function getRepositoryDirectories {
	$resolvedGitFolder = (Resolve-Path $GitFolder).Path

	Get-ChildItem -Path $resolvedGitFolder -Directory |
	Where-Object {
		Test-Path (Join-Path $_.FullName ".git")
	}
}

Function syncFork {
	getRepositoryDirectories |
	Foreach-Object {
		doSyncFork($_.FullName)
	}
}

Function doSyncFork {
	param ($Path)
	$RepoPath = (Resolve-Path $Path).Path
	$RepoName = Split-Path -Leaf $RepoPath

	Write-Output ***************************************
	Write-Output $RepoPath
	Write-Output ***************************************
	
	# Sync fork with GitHub-CLI
	gh repo sync $GhUsername/$RepoName
}

Function cleanGone {
	getRepositoryDirectories |
	Foreach-Object {
		doCleanGone($_.FullName)
	}
}

Function doCleanGone {
	param ($Path)
	$RepoPath = (Resolve-Path $Path).Path

	Write-Output ***************************************
	Write-Output $RepoPath
	Write-Output ***************************************
	
	# CD into directory
	Push-Location $RepoPath
	
	# Remove local branches that have been merged already
	git fetch --all --prune; git branch -vv | sls 'gone]' | % { git branch -D ($_.ToString().Split()[0]) }
	
	Pop-Location
}
	
Function switchToMaster {
	getRepositoryDirectories |
	Foreach-Object {
		doSwitchToMaster($_.FullName)
	}
}
	
Function doSwitchToMaster {
	param ($Path)
	$RepoPath = (Resolve-Path $Path).Path
	$RepoName = Split-Path -Leaf $RepoPath

	Write-Output ***************************************
	Write-Output $RepoPath
	Write-Output ***************************************

	# Sync fork with GitHub-CLI
	gh repo sync $GhUsername/$RepoName
	
	# CD into directory
	Push-Location $RepoPath
	
	# Switch to master, discard uncommitted/unstaged changes
	git checkout master -f
	
	Write-Output "Resetting everything, included untracked files"
	git reset --hard
	git clean -df
	
	git pull $RemoteName master
	git rebase $RemoteName/master
	
	Write-Output "Pruning deleted remote branches"
	git fetch --all --prune
	
	Pop-Location
}

Function switchToTaggedVersion {
	param ($Tag)
	
	getRepositoryDirectories |
	Foreach-Object {
		doSwitchToTaggedVersion $_.FullName $Tag
	}
}

Function doSwitchToTaggedVersion {
	param ($Path, $Tag)
	$RepoPath = (Resolve-Path $Path).Path
	$RepoName = Split-Path -Leaf $RepoPath

	Write-Output ***************************************
	Write-Output $RepoPath
	Write-Output ***************************************

	gh repo sync $GhUsername/$RepoName

	Push-Location -Path $RepoPath

	Write-Output "fetching tags: $Tag"
	git fetch $RemoteName tag $Tag --no-tags

	Write-Output "switching to $Tag"
	git checkout $Tag -f
	
	Write-Output "Resetting everything, included untracked files"
	git reset --hard
	git clean -df
	
	Pop-Location
}

Function switchToBranch {
	param ($Tag)
	
	getRepositoryDirectories |
	Foreach-Object {
		doSwitchToBranch $_.FullName $Tag
	}
}

Function doSwitchToBranch {
	param ($Path, $Branch)
	$RepoPath = (Resolve-Path $Path).Path
	$RepoName = Split-Path -Leaf $RepoPath

	Write-Output ***************************************
	Write-Output $RepoPath
	Write-Output ***************************************

	gh repo sync $GhUsername/$RepoName

	Push-Location -Path $RepoPath

 	Write-Output "fetching remote branch: $RemoteName/$Branch"
 	git remote set-branches --add $RemoteName $Branch
 	git fetch $RemoteName $Branch
		
 	Write-Output "switching to $Branch"
 	git checkout --track --force $RemoteName/$Branch
		
 	Write-Output "Resetting everything, included untracked files"
 	git reset --hard
 	git clean -df
		
 	Pop-Location
}
		
Function addRemotes {
	getRepositoryDirectories |
	Foreach-Object {
		doAddRemote($_.FullName)
	}
}
	
Function doAddRemote {
	param ($Path)
	$RepoPath = (Resolve-Path $Path).Path
	$RepoName = Split-Path -Leaf $RepoPath

	Write-Output ***************************************
	Write-Output $RepoPath
	Write-Output ***************************************

	Push-Location $RepoPath
	
	Write-Output "Removing remote $UserRemoteName"
	git remote remove $UserRemoteName
	
	Write-Output "Adding remote $UserRemoteName -> https://github.com/$GhUsername/$RepoName"
	git remote add $UserRemoteName https://github.com/$GhUsername/$RepoName
	
	Pop-Location
}
	
Function fetchRemoteBranches {
	getRepositoryDirectories |
	Foreach-Object {
		doFetchRemoteBranches($_.FullName)
	}
}
	
Function doFetchRemoteBranches {
	param ($Path)
	$RepoPath = (Resolve-Path $Path).Path

	Write-Output ***************************************
	Write-Output $RepoPath
	Write-Output ***************************************

	Push-Location $RepoPath
	
	Write-Output "Remove all tracked branches from all remotes"
	$branches = git branch -r
        $branches | ForEach-Object {
               $branchName = $_.Trim()  # Remove leading and trailing spaces
               git branch -r -d $branchName -q 2>$null
       }
	
	Write-Output "Fetch branches from my fork (except the master branch), no tags"
	git config remote.$UserRemoteName.fetch +refs/heads/*:refs/remotes/$UserRemoteName/*
	git config --add remote.$UserRemoteName.fetch '^refs/heads/master'
	git config remote.$UserRemoteName.tagopt --no-tags
	git fetch $UserRemoteName
	
	Write-Output "Delete the master branch of my own fork"
	git branch -d -r $UserRemoteName/master
	
	Write-Output "Fetch the master branch from origin, no tags"
	# Only track the master branch from "origin", no other branches
	git config --replace-all remote.$RemoteName.fetch +refs/heads/master:refs/remotes/$RemoteName/master
	git config remote.$RemoteName.tagopt --no-tags
	git fetch $RemoteName
	
	Pop-Location	
}

Function fetchAll {
	getRepositoryDirectories |
	Foreach-Object {
		doFetchAll($_.FullName)
	}
}

Function doFetchAll {
	param ($Path)
	$RepoPath = (Resolve-Path $Path).Path

	Write-Output ***************************************
	Write-Output $RepoPath
	Write-Output ***************************************

	Push-Location $RepoPath
	
	Write-Output "Pruning deleted remote branches"
	git fetch --all --prune
	
	Pop-Location	
}

Function changeForksToHTTPS {
	getRepositoryDirectories |
	Foreach-Object {
		doChangeForksToHTTPS($_.FullName)
	}
}
	
Function doChangeForksToHTTPS {
	param ($Path)
	$RepoPath = (Resolve-Path $Path).Path
	$RepoName = Split-Path -Leaf $RepoPath

	Write-Output ***************************************
	Write-Output $RepoPath
	Write-Output ***************************************

	Push-Location $RepoPath
	
	# Edit the remote
	git remote set-url $UserRemoteName https://github.com/$GhUsername/$RepoName
	
	Pop-Location
}
