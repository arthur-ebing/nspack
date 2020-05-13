const test = require('baretest')('Sum tests');
const assert = require('assert');
const sum = require('./sum');
const utils = require('../../public/js/crossbeams-utils');

test('1 + 2', function() {
  assert.equal(sum(1, 2), 3)
});

test('2 + 3', function() {
  assert.equal(sum(2, 3), 5)
});

  // nextDialogTitle: function nextDialogTitle() {
  //   switch (this.currentDialogLevel()) {
  //     case 2:
  //       return 'dialogTitleLevel2';
  //     case 1:
  //       return 'dialogTitleLevel2';
  //     default:
  //       return 'dialogTitleLevel1';
  //   }
  // },

test('nextTitle', function() {
  assert.equal(utils.crossbeamsUtils.nextDialogTitle(), 'dialogTitleLevel1');
});

test.run()
