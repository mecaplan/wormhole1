/**
 *  Some math functions three.js is lacking.
 */

var MathUtil = {
  Matrix3: {
    subtract: function(target, matrix) {
      for (var i = 0; i < 9; i++) {
        target.elements[i] -= matrix.elements[i];
      }
      return target;
    },

    getInverse: function(target, matrix) {
      var me = matrix.elements;
      var te = target.elements;

      var a00 = me[0], a01 = me[1], a02 = me[2],
          a10 = me[3], a11 = me[4], a12 = me[5],
          a20 = me[6], a21 = me[7], a22 = me[8],

          b01 = a22 * a11 - a12 * a21,
          b11 = -a22 * a10 + a12 * a20,
          b21 = a21 * a10 - a11 * a20,

          // Calculate the determinant
          det = a00 * b01 + a01 * b11 + a02 * b21;

      if (!det) {
        throw new Error("0 determinant");
      }

      te[0] = b01;
      te[1] = -a22 * a01 + a02 * a21;
      te[2] = a12 * a01 - a02 * a11;
      te[3] = b11;
      te[4] = a22 * a00 - a02 * a20;
      te[5] = -a12 * a00 + a02 * a10;
      te[6] = b21;
      te[7] = -a21 * a00 + a01 * a20;
      te[8] = a11 * a00 - a01 * a10;

      target.multiplyScalar( 1.0 / det );

      return target;
    },
  }
};

module.exports = MathUtil;
