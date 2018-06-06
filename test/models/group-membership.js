import chai from 'chai'
import Database from '../../src/database'
import * as User from '../../src/models/user'
import * as Group from '../../src/models/group'
import * as GroupRequest from '../../src/models/group-request'
import * as GroupMembership from '../../src/models/group-membership'
import '../index'


const should = chai.should()
const db = new Database()

var groupMembershipRequestId
var groupCreatorUserId
var groupRequesterId
var groupId

function insertUser(name) {
  return User.create(`${name}n`, `${name}p`, name)
}

function insertGroup(creatorId, name) {
  return Group.create(creatorId, `${name}n`, `${name}d`, `${name}p`)
}

describe.only('Models | GroupMembership', () => {
  before(async () => {
    // Create the users for testing
    groupCreatorUserId = await insertUser('GroupAuthorUser')
    groupRequesterId = await insertUser('GroupRequesterUser')

    // Create the group for testing
    groupId = await insertGroup(groupCreatorUserId, 'GroupName');

    // Create group membership request
    groupMembershipRequestId = await GroupRequest.create(groupRequesterId, groupId)
  })

  afterEach(() => {db.clear(GroupMembership.name)})

  after(() => {
    db.clear(Group.name)
    db.clear(GroupRequest.name)
    db.clear(GroupMembership.name)
    db.clear(User.name)
  })

  it('membership creation / acceptance from membership request by group owner', async () => {
  })

})
