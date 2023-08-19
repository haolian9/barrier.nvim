a dirty but effecient way to abort `:qa`/`:q`


## why?
i think when there are processes created by `uv.spawn(detached = false)`,
nvim should not allow `:qa`/`:q`. so i figured out this workaround.

especially for a [daemonized music player](https://github.com/haolian9/cricket.nvim).


## prerequisites
* haolian9/infra.nvim
* nvim 0.9.*


## usage
* .acquire/release(token) # the token can be arbitrary string but must be unique
* .tokens() # returning all the tokens that are still being held
