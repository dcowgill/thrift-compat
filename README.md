<pre>

    <b>dcowgill/thrift-compat</b>

    verifies some forward and backward compatibility properties
    of the thrift protocol, in multiple languages, with a focus
    on properties that are not made explicit in the thrift docs

    N.B. uses thrift 0.11.0

    <b>why</b>

    • can you add values to or remove values from an enum?
      what about unions? googling is surprisingly unhelpful

    • generated thrift clients in different languages behave
      differently, so it's dangerous assume based on any one

    <b>installation</b>

    first: <a href="https://golang.org/dl/">install go</a> if you don't have it

    $ go get github.com/dcowgill/thrift-compat
    $ cd $GOPATH/github.com/dcowgill/thrift-compat
    $ make

    <b>language support</b>

    just go and ruby for now

    <b>conclusions</b>

    assuming the normal rules of thrift compatibility are
    obeyed, like not reusing a numbered field

    • forward compatible (vN+1 can read vN):
      adding to enums, unions

    • backward compatible (vN can read vN+1):
      removing from enums, unions

    note that this differs from the usual thrift promise,
    where adding fields to a thing is typically ok

    also note:

    the generated go client will not raise errors when
    decoding a value that uses a non-existent union field
    or a non-existent enum value, so extra care must be
    taken to validate decoded objects

</pre>
