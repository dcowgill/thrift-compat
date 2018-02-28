<pre>

    <b>dcowgill/thrift-compat</b>

    Verifies some forward and backward compatibility properties
    of the thrift protocol, in multiple languages, with a focus
    on properties that are not made explicit in the thrift docs.

    N.B. uses thrift 0.11.0

    <b>Why</b>

    • Can you add values to or remove values from an enum?
      what about unions? Googling is surprisingly unhelpful.

    • Generated thrift clients in various languages sometimes
      behave differently, so it's dangerous to make assumptions
      based on any single one.

    <b>Installation</b>

    First: <a href="https://golang.org/dl/">install go</a> if you don't have it.

    $ go get github.com/dcowgill/thrift-compat
    $ cd $GOPATH/github.com/dcowgill/thrift-compat
    $ make

    <b>Language Support</b>

    Just Go and Ruby for now.

    <b>Conclusions</b>

    Assuming the normal rules of thrift compatibility are
    obeyed, such as not reusing a numbered field:

    • forward compatible (version N+1 can read version N):
      adding to enums, unions
      <strike>removing from enums or unions</strike>

    • backward compatible (version N can read version N+1):
      <strike>adding to enums or unions</strike>
      removing from enums or unions

    In other words, modifying enums or unions is generally
    <i>not</i> a compatible change.

    Note that this differs from the usual thrift promise,
    where adding fields to a thing is typically ok.

    Also note:

    The generated go client will not raise errors when
    decoding a value that uses a non-existent union field
    or a non-existent enum value, so extra care must be
    taken to validate decoded objects.

</pre>
