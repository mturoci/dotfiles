local jobopts = { rpc = true, width = 80, height = 24, env = { NVIM_ENV = 'test' } }
local eq = assert.is.equal
local original_file_content = {}
local original_file_content_ours_longer = {}
local original_file_content_theirs_longer = {}
local fixture_file = './test/fixtures/conflict_other.txt'
local fixture_file_ours_longer = './test/fixtures/conflict_ours_longer.txt'
local fixture_file_theirs_longer = './test/fixtures/conflict_theirs_longer.txt'
local utils = require 'test.e2e.test_utils'

describe('Conflict accept', function()
  local nvim

  -- TODO: Do not spawn a new process for each test. Closing should be enough.
  before_each(function()
    nvim = vim.fn.jobstart({ 'nvim', '--embed', '--headless' }, jobopts)
    original_file_content = vim.fn.readfile(fixture_file)
    original_file_content_ours_longer = vim.fn.readfile(fixture_file_ours_longer)
    original_file_content_theirs_longer = vim.fn.readfile(fixture_file_theirs_longer)
  end)

  after_each(function()
    print(vim.fn.rpcrequest(nvim, 'nvim_eval', "execute('messages')"))
    vim.fn.jobstop(nvim)
    vim.fn.writefile(original_file_content, fixture_file)
    vim.fn.writefile(original_file_content_ours_longer, fixture_file_ours_longer)
    vim.fn.writefile(original_file_content_theirs_longer, fixture_file_theirs_longer)
  end)


  it('Accepts ours conflict and updates all buffers properly', function()
    utils.open_file(nvim, fixture_file)
    vim.fn.rpcrequest(nvim, 'nvim_input', 'j')


    utils.accept_conflict(nvim)
    local result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', utils.LEFT_BUFFER, 0, -1, false)
    local expected = 'Regular text.\nOurs conflict.\nRegular text.'
    eq(expected, table.concat(result, '\n'))
    result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', utils.ORIGINAL_BUFFER, 0, -1, false)
    eq(expected, table.concat(result, '\n'))
    result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', utils.RIGHT_BUFFER, 0, -1, false)
    eq(expected, table.concat(result, '\n'))
  end)

  it('Accepts ours conflict and updates all buffers properly - theirs longer', function()
    utils.open_file(nvim, fixture_file_theirs_longer)
    vim.fn.rpcrequest(nvim, 'nvim_input', 'j')

    utils.accept_conflict(nvim)
    local result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', utils.LEFT_BUFFER, 0, -1, false)
    local expected = 'Ours conflict.'
    eq(expected, table.concat(result, '\n'))
    result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', utils.ORIGINAL_BUFFER, 0, -1, false)
    eq(expected, table.concat(result, '\n'))
    result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', 0, 0, -1, false)
    eq(expected, table.concat(result, '\n'))
  end)

  it('Accepts ours conflict and updates all buffers properly - ours longer', function()
    utils.open_file(nvim, fixture_file_ours_longer)

    utils.accept_conflict(nvim)
    local result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', utils.ORIGINAL_BUFFER, 0, -1, false)
    local expected = 'Ours conflict.\nOurs conflict.'
    eq(expected, table.concat(result, '\n'))
    result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', utils.LEFT_BUFFER, 0, -1, false)
    eq(expected, table.concat(result, '\n'))
    result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', utils.RIGHT_BUFFER, 0, -1, false)
    eq(expected, table.concat(result, '\n'))
  end)

  it('Accepts theirs conflict and updates all buffers properly', function()
    utils.open_file(nvim, fixture_file)
    vim.fn.rpcrequest(nvim, 'nvim_input', '<C-W>w')
    vim.fn.rpcrequest(nvim, 'nvim_input', 'j')

    utils.accept_conflict(nvim)
    local result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', utils.LEFT_BUFFER, 0, -1, false)
    local expected = 'Regular text.\nTheirs conflict.\nRegular text.'
    eq(expected, table.concat(result, '\n'))
    result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', utils.ORIGINAL_BUFFER, 0, -1, false)
    eq(expected, table.concat(result, '\n'))
    result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', 0, 0, -1, false)
    eq(expected, table.concat(result, '\n'))
  end)

  it('Accepts theirs conflict and updates all buffers properly - ours longer', function()
    utils.open_file(nvim, fixture_file_ours_longer)
    vim.fn.rpcrequest(nvim, 'nvim_input', '<C-W>w')

    utils.accept_conflict(nvim)
    local result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', utils.RIGHT_BUFFER, 0, -1, false)
    local expected = 'Theirs conflict.'
    eq(expected, table.concat(result, '\n'))
    result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', utils.LEFT_BUFFER, 0, -1, false)
    eq(expected, table.concat(result, '\n'))
    result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', utils.ORIGINAL_BUFFER, 0, -1, false)
    eq(expected, table.concat(result, '\n'))
  end)

  it('Accepts ours conflict and updates all buffers properly - theirs longer', function()
    utils.open_file(nvim, fixture_file_theirs_longer)

    utils.accept_conflict(nvim)

    local result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', utils.LEFT_BUFFER, 0, -1, false)
    local expected = 'Ours conflict.'
    eq(expected, table.concat(result, '\n'))
    result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', utils.ORIGINAL_BUFFER, 0, -1, false)
    eq(expected, table.concat(result, '\n'))
    result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', utils.RIGHT_BUFFER, 0, -1, false)
    eq(expected, table.concat(result, '\n'))
  end)

  it('Does not do anything if cursor not at conflict', function()
    utils.open_file(nvim, fixture_file)

    utils.accept_conflict(nvim)
    local result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', utils.LEFT_BUFFER, 0, -1, false)
    eq('Regular text.\nOurs conflict.\nRegular text.', table.concat(result, '\n'))
    result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', utils.ORIGINAL_BUFFER, 0, -1, false)
    eq(table.concat(original_file_content, '\n'), table.concat(result, '\n'))
    result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', utils.RIGHT_BUFFER, 0, -1, false)
    eq('Regular text.\nTheirs conflict.\nRegular text.', table.concat(result, '\n'))
  end)

  it('Accepts both - ours buf', function()
    utils.open_file(nvim, fixture_file)
    vim.fn.rpcrequest(nvim, 'nvim_input', 'j')
    utils.accept_both_conflicts(nvim)

    local result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', utils.ORIGINAL_BUFFER, 0, -1, false)
    eq('Regular text.\nOurs conflict.\nTheirs conflict.\nRegular text.', table.concat(result, '\n'))
    result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', utils.LEFT_BUFFER, 0, -1, false)
    eq('Regular text.\nOurs conflict.\nTheirs conflict.\nRegular text.', table.concat(result, '\n'))
    result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', utils.RIGHT_BUFFER, 0, -1, false)
    eq('Regular text.\nOurs conflict.\nTheirs conflict.\nRegular text.', table.concat(result, '\n'))
  end)

  it('Accepts both - ours buf - ours longer', function()
    utils.open_file(nvim, './test/fixtures/conflict_ours_longer.txt')
    vim.fn.rpcrequest(nvim, 'nvim_input', 'j')

    utils.accept_both_conflicts(nvim)
    local expected = [[
Ours conflict.
Ours conflict.
Theirs conflict.]]

    local result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', utils.ORIGINAL_BUFFER, 0, -1, false)
    eq(expected, table.concat(result, '\n'))
    result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', utils.LEFT_BUFFER, 0, -1, false)
    eq(expected, table.concat(result, '\n'))
    result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', utils.RIGHT_BUFFER, 0, -1, false)
    eq(expected, table.concat(result, '\n'))
  end)

  it('Accepts both - ours buf - theirs longer', function()
    utils.open_file(nvim, './test/fixtures/conflict_theirs_longer.txt')
    vim.fn.rpcrequest(nvim, 'nvim_input', 'j')

    local leader_key = vim.fn.rpcrequest(nvim, 'nvim_eval', 'mapleader')
    vim.fn.rpcrequest(nvim, 'nvim_feedkeys', vim.api.nvim_replace_termcodes(leader_key .. 'b', true, false, true), 'm',
      true)

    -- Add sleep to wait for the command to finish.
    vim.fn.rpcrequest(nvim, 'nvim_command', 'sleep 100m')
    local expected = [[
Ours conflict.
Theirs conflict.
Theirs conflict.]]

    local result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', utils.ORIGINAL_BUFFER, 0, -1, false)
    eq(expected, table.concat(result, '\n'))
    result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', utils.LEFT_BUFFER, 0, -1, false)
    eq(expected, table.concat(result, '\n'))
    result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', utils.RIGHT_BUFFER, 0, -1, false)
    eq(expected, table.concat(result, '\n'))
  end)

  it('Accepts both - theirs buf', function()
    utils.open_file(nvim, fixture_file)
    vim.fn.rpcrequest(nvim, 'nvim_input', '<C-W>w')
    vim.fn.rpcrequest(nvim, 'nvim_input', 'j')

    utils.accept_both_conflicts(nvim)

    local result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', utils.ORIGINAL_BUFFER, 0, -1, false)
    eq('Regular text.\nOurs conflict.\nTheirs conflict.\nRegular text.', table.concat(result, '\n'))
    result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', utils.LEFT_BUFFER, 0, -1, false)
    eq('Regular text.\nOurs conflict.\nTheirs conflict.\nRegular text.', table.concat(result, '\n'))
    result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', utils.RIGHT_BUFFER, 0, -1, false)
    eq('Regular text.\nOurs conflict.\nTheirs conflict.\nRegular text.', table.concat(result, '\n'))
  end)

  it('Accepts both - theirs buf - ours longer', function()
    utils.open_file(nvim, './test/fixtures/conflict_ours_longer.txt')
    vim.fn.rpcrequest(nvim, 'nvim_input', '<C-W>w')
    vim.fn.rpcrequest(nvim, 'nvim_input', 'j')

    utils.accept_both_conflicts(nvim)
    local expected = [[
Ours conflict.
Ours conflict.
Theirs conflict.]]

    local result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', utils.ORIGINAL_BUFFER, 0, -1, false)
    eq(expected, table.concat(result, '\n'))
    result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', utils.LEFT_BUFFER, 0, -1, false)
    eq(expected, table.concat(result, '\n'))
    result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', utils.RIGHT_BUFFER, 0, -1, false)
    eq(expected, table.concat(result, '\n'))
  end)

  it('Accepts both - theirs buf - theirs longer', function()
    utils.open_file(nvim, './test/fixtures/conflict_theirs_longer.txt')
    vim.fn.rpcrequest(nvim, 'nvim_input', '<C-W>w')
    vim.fn.rpcrequest(nvim, 'nvim_input', 'j')

    utils.accept_both_conflicts(nvim)
    local expected = [[
Ours conflict.
Theirs conflict.
Theirs conflict.]]

    local result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', utils.ORIGINAL_BUFFER, 0, -1, false)
    eq(expected, table.concat(result, '\n'))
    result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', utils.LEFT_BUFFER, 0, -1, false)
    eq(expected, table.concat(result, '\n'))
    result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', utils.RIGHT_BUFFER, 0, -1, false)
    eq(expected, table.concat(result, '\n'))
  end)

  it('Does not do anything if accepts both but cursor not at conflict', function()
    utils.open_file(nvim, fixture_file)

    utils.accept_both_conflicts(nvim)

    local result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', utils.LEFT_BUFFER, 0, -1, false)
    eq('Regular text.\nOurs conflict.\nRegular text.', table.concat(result, '\n'))
    result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', utils.ORIGINAL_BUFFER, 0, -1, false)
    eq(table.concat(original_file_content, '\n'), table.concat(result, '\n'))
    result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', utils.RIGHT_BUFFER, 0, -1, false)
    eq('Regular text.\nTheirs conflict.\nRegular text.', table.concat(result, '\n'))
  end)

  it('Accepts first conflict when conflicts are adjacent with zero lines between', function()
    utils.open_file(nvim, './test/fixtures/conflict_adjacent.txt')

    utils.accept_conflict(nvim)

    local expected = [[
Ours conflict 1.
Ours conflict 2.]]
    local result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', utils.LEFT_BUFFER, 0, -1, false)
    eq(expected, table.concat(result, '\n'))
    result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', utils.RIGHT_BUFFER, 0, -1, false)
    expected = [[
Ours conflict 1.
Theirs conflict 2.]]
    eq(expected, table.concat(result, '\n'))
    result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', utils.ORIGINAL_BUFFER, 0, -1, false)
    expected = [[
Ours conflict 1.
<<<<<<< HEAD
Ours conflict 2.
=======
Theirs conflict 2.
>>>>>>> another-branch]]
    eq(expected, table.concat(result, '\n'))
  end)

  it('Accepts second conflict when conflicts are adjacent - after jumping', function()
    utils.open_file(nvim, './test/fixtures/conflict_adjacent.txt')
    vim.fn.rpcrequest(nvim, 'nvim_input', '[c')

    utils.accept_conflict(nvim)

    local expected = [[
Ours conflict 1.
Ours conflict 2.]]
    local result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', utils.LEFT_BUFFER, 0, -1, false)
    eq(expected, table.concat(result, '\n'))
    expected = [[
Theirs conflict 1.
Ours conflict 2.]]
    result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', utils.RIGHT_BUFFER, 0, -1, false)
    eq(expected, table.concat(result, '\n'))
    expected = [[
<<<<<<< HEAD
Ours conflict 1.
=======
Theirs conflict 1.
>>>>>>> another-branch
Ours conflict 2.]]
    result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', utils.ORIGINAL_BUFFER, 0, -1, false)
    eq(expected, table.concat(result, '\n'))
  end)

  it('Restores conflict markers after undoing accept ours', function()
    utils.open_file(nvim, fixture_file)
    vim.fn.rpcrequest(nvim, 'nvim_input', 'j')

    utils.accept_conflict(nvim)
    local accepted = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', utils.ORIGINAL_BUFFER, 0, -1, false)
    eq('Regular text.\nOurs conflict.\nRegular text.', table.concat(accepted, '\n'))

    vim.fn.rpcrequest(nvim, 'nvim_command', 'normal u')
    local result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', utils.ORIGINAL_BUFFER, 0, -1, false)
    eq(table.concat(original_file_content, '\n'), table.concat(result, '\n'))

    result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', utils.LEFT_BUFFER, 0, -1, false)
    eq('Regular text.\nOurs conflict.\nRegular text.', table.concat(result, '\n'))
    result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', utils.RIGHT_BUFFER, 0, -1, false)
    eq('Regular text.\nTheirs conflict.\nRegular text.', table.concat(result, '\n'))
  end)

  it('Restores conflict markers after undoing accept both', function()
    utils.open_file(nvim, fixture_file)
    vim.fn.rpcrequest(nvim, 'nvim_input', 'j')

    utils.accept_both_conflicts(nvim)
    local accepted = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', utils.ORIGINAL_BUFFER, 0, -1, false)
    eq('Regular text.\nOurs conflict.\nTheirs conflict.\nRegular text.', table.concat(accepted, '\n'))

    vim.fn.rpcrequest(nvim, 'nvim_command', 'normal u')
    local result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', utils.ORIGINAL_BUFFER, 0, -1, false)
    eq(table.concat(original_file_content, '\n'), table.concat(result, '\n'))

    result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', utils.LEFT_BUFFER, 0, -1, false)
    eq('Regular text.\nOurs conflict.\nRegular text.', table.concat(result, '\n'))
    result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', utils.RIGHT_BUFFER, 0, -1, false)
    eq('Regular text.\nTheirs conflict.\nRegular text.', table.concat(result, '\n'))
  end)

  it('Allows redo after undoing accept', function()
    utils.open_file(nvim, fixture_file)
    vim.fn.rpcrequest(nvim, 'nvim_input', 'j')

    utils.accept_conflict(nvim)
    vim.fn.rpcrequest(nvim, 'nvim_command', 'normal u')
    vim.fn.rpcrequest(nvim, 'nvim_input', '<C-r>')

    local result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', utils.ORIGINAL_BUFFER, 0, -1, false)
    eq('Regular text.\nOurs conflict.\nRegular text.', table.concat(result, '\n'))
    result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', utils.LEFT_BUFFER, 0, -1, false)
    eq('Regular text.\nOurs conflict.\nRegular text.', table.concat(result, '\n'))
    result = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', utils.RIGHT_BUFFER, 0, -1, false)
    eq('Regular text.\nOurs conflict.\nRegular text.', table.concat(result, '\n'))
  end)

  it('Handles multiple accept operations on already resolved conflict - accept ours twice', function()
    utils.open_file(nvim, fixture_file)
    vim.fn.rpcrequest(nvim, 'nvim_input', 'j')

    utils.accept_conflict(nvim)
    local first_accept = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', utils.ORIGINAL_BUFFER, 0, -1, false)
    eq('Regular text.\nOurs conflict.\nRegular text.', table.concat(first_accept, '\n'))

    utils.accept_conflict(nvim)
    local second_accept = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', utils.ORIGINAL_BUFFER, 0, -1, false)
    eq('Regular text.\nOurs conflict.\nRegular text.', table.concat(second_accept, '\n'))

    local left = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', utils.LEFT_BUFFER, 0, -1, false)
    eq('Regular text.\nOurs conflict.\nRegular text.', table.concat(left, '\n'))
    local right = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', utils.RIGHT_BUFFER, 0, -1, false)
    eq('Regular text.\nOurs conflict.\nRegular text.', table.concat(right, '\n'))
  end)

  it('Handles multiple accept both operations on same conflict', function()
    utils.open_file(nvim, fixture_file)
    vim.fn.rpcrequest(nvim, 'nvim_input', 'j')

    utils.accept_both_conflicts(nvim)
    local first_accept = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', utils.ORIGINAL_BUFFER, 0, -1, false)
    eq('Regular text.\nOurs conflict.\nTheirs conflict.\nRegular text.', table.concat(first_accept, '\n'))

    utils.accept_both_conflicts(nvim)
    local second_accept = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', utils.ORIGINAL_BUFFER, 0, -1, false)
    eq('Regular text.\nOurs conflict.\nTheirs conflict.\nRegular text.', table.concat(second_accept, '\n'))
  end)

  it('Handles switching from ours to theirs on same conflict position', function()
    utils.open_file(nvim, fixture_file)
    vim.fn.rpcrequest(nvim, 'nvim_input', 'j')

    utils.accept_conflict(nvim)
    local ours_accepted = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', utils.ORIGINAL_BUFFER, 0, -1, false)
    eq('Regular text.\nOurs conflict.\nRegular text.', table.concat(ours_accepted, '\n'))

    vim.fn.rpcrequest(nvim, 'nvim_input', '<C-W>w')
    vim.fn.rpcrequest(nvim, 'nvim_input', 'j')
    utils.accept_conflict(nvim)

    local theirs_accepted = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', utils.ORIGINAL_BUFFER, 0, -1, false)
    eq('Regular text.\nOurs conflict.\nRegular text.', table.concat(theirs_accepted, '\n'))
  end)

  it('Handles accept both after accepting ours', function()
    utils.open_file(nvim, fixture_file)
    vim.fn.rpcrequest(nvim, 'nvim_input', 'j')

    utils.accept_conflict(nvim)
    local ours_accepted = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', utils.ORIGINAL_BUFFER, 0, -1, false)
    eq('Regular text.\nOurs conflict.\nRegular text.', table.concat(ours_accepted, '\n'))

    utils.accept_both_conflicts(nvim)
    local both_accepted = vim.fn.rpcrequest(nvim, 'nvim_buf_get_lines', utils.ORIGINAL_BUFFER, 0, -1, false)
    eq('Regular text.\nOurs conflict.\nRegular text.', table.concat(both_accepted, '\n'))
  end)
end)
