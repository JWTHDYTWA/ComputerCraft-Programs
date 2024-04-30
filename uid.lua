local lib = {
    uid = function ()
        return os.epoch('utc')
    end
}