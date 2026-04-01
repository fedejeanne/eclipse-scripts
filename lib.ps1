param(
	[string]$GitFolder = "$PSScriptRoot\..\platform-master2\git",
	[string]$GhUsername = "fedejeanne",
	[string]$RemoteName = "origin",
	[string]$UserRemoteName
)

if (-not $PSBoundParameters.ContainsKey('UserRemoteName')) {
	$UserRemoteName = $GhUsername
}

Function syncFork {
	Get-ChildItem $GitFolder | Select-Object Name | 
	Foreach-Object {
		doSyncFork($_.Name)
	}
}

Function doSyncFork {
	param ($Path)
	Write-Output ***************************************
	Write-Output $Path
	Write-Output ***************************************
	
	# Sync fork with GitHub-CLI
	gh repo sync $GhUsername/$Path
}

Function cleanGone {
	$resolvedGitFolder = Resolve-Path $GitFolder

	Get-ChildItem $resolvedGitFolder -Directory | Select-Object FullName | 
	Foreach-Object {
		doCleanGone($_.FullName)
	}
}

Function doCleanGone {
	param ($Path)
	Write-Output ***************************************
	Write-Output $Path
	Write-Output ***************************************
	
	# CD into directory
	Push-Location $Path
	
	# Remove local branches that have been merged already
	git fetch --all --prune; git branch -vv | sls 'gone]' | % { git branch -D ($_.ToString().Split()[0]) }
	
	Pop-Location
}
	
Function switchToMaster {
	Push-Location $GitFolder

	Get-ChildItem . | Select-Object Name | 
	Foreach-Object {
		doSwitchToMaster($_.Name)
	}

	Pop-Location
}
	
Function doSwitchToMaster {
	param ($Path)
	Write-Output ***************************************
	Write-Output $Path
	Write-Output ***************************************

	# Sync fork with GitHub-CLI
	gh repo sync $GhUsername/$Path
	
	# CD into directory
	Push-Location $Path
	
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
	
	Push-Location $GitFolder

	Get-ChildItem . | Select-Object Name | 
	Foreach-Object {
		doSwitchToTaggedVersion $_.Name $Tag
	}
}

Function doSwitchToTaggedVersion {
	param ($Path, $Tag)
	Write-Output ***************************************
	Write-Output $Path
	Write-Output ***************************************

	gh repo sync $GhUsername/$Path

	Push-Location -Path $Path

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
	
	Push-Location $GitFolder

	Get-ChildItem . | Select-Object Name | 
	Foreach-Object {
		doSwitchToBranch $_.Name $Tag
	}
}

Function doSwitchToBranch {
	param ($Path, $Branch)
	Write-Output ***************************************
	Write-Output $Path
	Write-Output ***************************************

	gh repo sync $GhUsername/$Path

	Push-Location -Path $Path

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
	Push-Location $GitFolder

	Get-ChildItem . | Select-Object Name | 
	Foreach-Object {
		doAddRemote($_.Name)
	}

	Pop-Location
}
	
Function doAddRemote {
	param ($Path)
	Write-Output ***************************************
	Write-Output $Path
	Write-Output ***************************************

	Push-Location $Path
	
	Write-Output "Removing remote $UserRemoteName"
	git remote remove $UserRemoteName
	
	Write-Output "Adding remote $UserRemoteName -> https://github.com/$GhUsername/$Path"
	git remote add $UserRemoteName https://github.com/$GhUsername/$Path
	
	Pop-Location
}
	
Function fetchRemoteBranches {
	Push-Location $GitFolder

	Get-ChildItem . | Select-Object Name | 
	Foreach-Object {
		doFetchRemoteBranches($_.Name)
	}
	
	Pop-Location
}
	
Function doFetchRemoteBranches {
	param ($Path)
	Write-Output ***************************************
	Write-Output $Path
	Write-Output ***************************************

	Push-Location $Path
	
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
	Push-Location $GitFolder

	Get-ChildItem . | Select-Object Name | 
	Foreach-Object {
		doFetchAll($_.Name)
	}
	
	Pop-Location
}

Function doFetchAll {
	param ($Path)
	Write-Output ***************************************
	Write-Output $Path
	Write-Output ***************************************

	Push-Location $Path
	
	Write-Output "Pruning deleted remote branches"
	git fetch --all --prune
	
	Pop-Location	
}

Function changeForksToHTTPS {
	Push-Location $GitFolder

	Get-ChildItem . | Select-Object Name | 
	Foreach-Object {
		doChangeForksToHTTPS($_.Name)
	}

	Pop-Location
}
	
Function doChangeForksToHTTPS {
	param ($Path)
	Write-Output ***************************************
	Write-Output $Path
	Write-Output ***************************************

	Push-Location $Path
	
	# Edit the remote
	git remote set-url $UserRemoteName https://github.com/$GhUsername/$Path
	
	Pop-Location
}
