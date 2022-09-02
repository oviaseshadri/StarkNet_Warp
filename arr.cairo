%builtins output

from starkware.cairo.common.serialize import serialize_word

func main{output_ptr : felt*}():
    serialize_word(1234)
    serialize_word(4321)
    return ()
end

# Computes the sum of the memory elements at addresses:
#   arr + 0, arr + 1, ..., arr + (size - 1).
func array_sum(arr : felt*, size) -> (sum : felt):
    if size == 0:
        return (sum=0)
    end

    # size is not zero.
    let (sum_of_rest) = array_sum(arr=arr + 1, size=size - 1)
    return (sum=[arr] + sum_of_rest)
end