const transitions={
  CREATED:new Set(['PENDING','CASH_DUE','FAILED','CANCELLED']),
  PENDING:new Set(['AUTHORIZED','CAPTURED','FAILED','CANCELLED']),
  AUTHORIZED:new Set(['CAPTURED','FAILED','CANCELLED']),
  CASH_DUE:new Set(['CASH_COLLECTED','FAILED','CANCELLED']),
  CAPTURED:new Set(['PARTIALLY_REFUNDED','REFUNDED']),
  CASH_COLLECTED:new Set(['PARTIALLY_REFUNDED','REFUNDED']),
  PARTIALLY_REFUNDED:new Set(['PARTIALLY_REFUNDED','REFUNDED']),
  FAILED:new Set([]),CANCELLED:new Set([]),REFUNDED:new Set([])
};
export function assertPaymentTransition(from,to){if(from===to)return true;if(!transitions[from]?.has(to))throw new Error(`Invalid payment transition: ${from} -> ${to}`);return true;}
export const paidStatuses=new Set(['CAPTURED','CASH_COLLECTED','PARTIALLY_REFUNDED','REFUNDED']);
