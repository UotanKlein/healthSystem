ix.command.Add("Suicide", {
    description = "@cmdSuicide",
    OnRun = function(self, client, maximum)
        client:Kill()
    end
})