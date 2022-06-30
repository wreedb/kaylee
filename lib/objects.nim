type #*#[ package object ]#
  Package* = object
    Name*, Description*, Version*, URLPath*: string
    LastModified*, NumVotes*, ID*: int
    

type #*#[ update package object ]#
  UpdatingPackage* = object
    Name*: string
    LastModified*: int