$GIT_FOLDER = "platform-contributor-all\git"

# GitHub username
$GH_USERNAME = "fedejeanne"

# The "main" remote (the one from eclipse)
$REMOTE_NAME = "origin"

# My remote, where the forks are (fedejeanne-origin)
$USER_REMOTE_NAME = $GH_USERNAME + "-origin"

Function syncFork {
	Get-ChildItem $GIT_FOLDER | Select-Object Name | 
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
	gh repo sync $GH_USERNAME/$Path
	
	
}
	
Function switchToMaster {
	Push-Location $GIT_FOLDER

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
	gh repo sync $GH_USERNAME/$Path
	
	# CD into directory
	Push-Location $Path
	
	# Switch to master, discard uncommitted/unstaged changes
	git checkout master -f
	
	Write-Output "Resetting everything, included untracked files"
	git reset --hard
	git clean -df
	
	git pull $REMOTE_NAME master
	git rebase $REMOTE_NAME/master
	
	Write-Output "Pruning deleted remote branches"
	git fetch --all --prune
	
	Pop-Location
	
}
	

Function switchToTaggedVersion {
	param ($Tag)
	
	Get-ChildItem $GIT_FOLDER | Select-Object Name | 
	Foreach-Object {
		doSwitchToTaggedVersion($_.Name, $Tag)
	}
}

Function doSwitchToTaggedVersion {
	param ($Path, $Tag)
	Write-Output ***************************************
	Write-Output $Path
	Write-Output ***************************************

	gh repo sync $GH_USERNAME/$Path

	Push-Location $Path

	Write-Output "fetching tags: $Tag"
	git fetch $REMOTE_NAME tag $Tag --no-tags

	Write-Output "switching to $Tag"
	git checkout $Tag -f
	
	Write-Output "Resetting everything, included untracked files"
	git reset --hard
	git clean -df
	
	Pop-Location
}

# Function switchToRemoteBranch {
# 	Push-Location $GIT_FOLDER
	
# 	Set-Variable REMOTE_NAME=origin
# 	Set-Variable REMOTE_BRANCH=%~2

# 	for (/D %%d in ( * )) {
# 		CALL :doSwitchToRemoteBranch %%d
# 	}

# 	Pop-Location
	
		
# 	:doSwitchToRemoteBranch
# 	Write-Output ***************************************
# 	Write-Output $Path
# 	Write-Output ***************************************
		
# 	Push-Location $Path
		
# 	Write-Output "fetching remote branch: $REMOTE_NAME/%REMOTE_BRANCH%"
# 	git remote set-branches --add $REMOTE_NAME %REMOTE_BRANCH%
# 	git fetch $REMOTE_NAME %REMOTE_BRANCH%
		
# 	Write-Output "switching to %REMOTE_BRANCH%"
# 	git checkout --track --force $REMOTE_NAME/%REMOTE_BRANCH%
		
# 	Write-Output "Resetting everything, included untracked files"
# 	git reset --hard
# 	git clean -df
		
# 	Pop-Location
	
# }
		
Function addRemotes {
	Push-Location $GIT_FOLDER

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
	
	Write-Output "Adding remote https://github.com/$GH_USERNAME/$Path"
	git remote add $USER_REMOTE_NAME https://github.com/$GH_USERNAME/$Path
	
	Pop-Location
}
	
Function fetchRemoteBranches {
	Push-Location $GIT_FOLDER

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
	
	# Remove all tracked branches from all remotes
	$branches = git branch -r
        $branches | ForEach-Object {
               $branchName = $_.Trim()  # Remove leading and trailing spaces
               git branch -r -d $branchName -q 2>$null
       }
	
	# Track almost all the branches from my forks (not the "master" branch) without tags
	git config remote.$USER_REMOTE_NAME.fetch +refs/heads/*:refs/remotes/$USER_REMOTE_NAME/*
	# git config --add remote.$USER_REMOTE_NAME.fetch '^refs/heads/master'
	git config remote.$USER_REMOTE_NAME.tagopt --no-tags
	git fetch $USER_REMOTE_NAME
	
	# Do not track the "master" branch from my own fork (this will be undone by the next "fetch" on my fork)
	git branch -d -r $USER_REMOTE_NAME/master
	
	# Track only the "master" branch from origin and no tags
	git config remote.$REMOTE_NAME.fetch +refs/heads/master:refs/remotes/$REMOTE_NAME/master
	git config remote.$REMOTE_NAME.tagopt --no-tags
	git fetch $REMOTE_NAME
	
	Pop-Location	
}