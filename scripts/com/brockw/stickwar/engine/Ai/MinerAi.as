package com.brockw.stickwar.engine.Ai
{
   import com.brockw.game.Util;
   import com.brockw.stickwar.engine.Ai.command.*;
   import com.brockw.stickwar.engine.Gold;
   import com.brockw.stickwar.engine.Ore;
   import com.brockw.stickwar.engine.StickWar;
   import com.brockw.stickwar.engine.units.*;
   
   public class MinerAi extends UnitAi
   {
      
      private var _targetOre:Ore;
      
      private var _isGoingForOre:Boolean;
      
      private var _isUnassigned:Boolean;
      
      public function MinerAi(s:Miner)
      {
         super();
         unit = s;
         this.targetOre = null;
         this.isGoingForOre = true;
         this._isUnassigned = true;
      }
      
      override public function init() : void
      {
         super.init();
         this.targetOre = null;
         this._isGoingForOre = true;
         this._isUnassigned = true;
      }
      
      override public function update(game:StickWar) : void
      {
         var yWalk:Number = NaN;
         var xWalking:Number = NaN;
         var yOffset:Number = NaN;
         var yMovement:Number = NaN;
         var offset:Number = NaN;
         if(this.targetOre != null)
         {
            this._isUnassigned = false;
         }
         if(this.targetOre == null)
         {
            this._isUnassigned = true;
         }
         unit.mayWalkThrough = false;
         checkNextMove(game);
         var target:Unit = this.getClosestTarget();
         if(mayAttack && unit.mayAttack(target))
         {
            if(target.damageWillKill(0,unit.damageToDeal) && unit.getDirection() != target.getDirection() && unit.getDirection() == Util.sgn(target.px - unit.px))
            {
               unit.attack();
            }
            else
            {
               unit.attack();
            }
         }
         else if(currentCommand.type == UnitCommand.CONSTRUCT_WALL && !currentCommand.inRange(unit))
         {
            unit.mayWalkThrough = true;
            unit.isBusyForSpell = true;
            unit.walk((currentCommand.realX - unit.px) / 20,(currentCommand.realY - unit.py) / 20,intendedX);
         }
         else if(this.currentCommand.type == UnitCommand.CONSTRUCT_WALL)
         {
            Miner(unit).buildWall(currentCommand.realX,currentCommand.realY);
            nextMove(game);
         }
         else if(currentCommand.type == UnitCommand.CONSTRUCT_TOWER && !currentCommand.inRange(unit))
         {
            unit.mayWalkThrough = true;
            unit.isBusyForSpell = true;
            unit.walk((currentCommand.realX - unit.px) / 20,(currentCommand.realY - unit.py) / 20,intendedX);
         }
         else if(this.currentCommand.type == UnitCommand.CONSTRUCT_TOWER)
         {
            MinerChaos(unit).buildTower(currentCommand.realX,currentCommand.realY);
            nextMove(game);
         }
         else if(this.targetOre != null && !unit.isGarrisoned)
         {
            unit.mayWalkThrough = true;
            if(Miner(unit).isBagFull())
            {
               if(this.targetOre != null)
               {
                  this.targetOre.releaseMiningSpot(Miner(unit));
               }
               yWalk = game.map.height / 2 - unit.py;
               if(Math.abs(yWalk) < 40)
               {
                  yWalk = 0;
               }
               unit.walk((unit.team.homeX - unit.x) / 20,yWalk / 20,(unit.team.homeX - unit.x) / 20);
            }
            else if(this.targetOre != null && !unit.isGarrisoned)
            {
               if(!this.targetOre.inMineRange(Miner(unit)))
               {
                  xWalking = this.targetOre.x - unit.team.direction * 125 - unit.x;
                  unit.walk(xWalking / 20,0,xWalking / 20);
               }
               else
               {
                  if(!this.targetOre.hasMiningSpot(Miner(unit)))
                  {
                     if(!this.targetOre.reserveMiningSpot(Miner(unit)))
                     {
                        xWalking = this.targetOre.x - unit.team.direction * 110 - unit.x;
                        unit.walk(xWalking / 20,(this.targetOre.y - unit.y) / 20,xWalking / 20);
                        if(Math.abs(xWalking) < 5)
                        {
                           unit.faceDirection(this.targetOre.x - unit.x);
                        }
                     }
                  }
                  if(this.targetOre.hasMiningSpot(Miner(unit)))
                  {
                     yOffset = this.targetOre.getMiningSpot(Miner(unit));
                     xWalking = this.targetOre.x - unit.team.direction * 50 - unit.x;
                     if(this.targetOre is Gold)
                     {
                        xWalking = this.targetOre.x + this.targetOre.getMiningSpot(Miner(unit)) - unit.x;
                        yOffset = 0;
                     }
                     if(Math.abs(xWalking) < 1)
                     {
                        Miner(unit).faceDirection(this._targetOre.x - unit.x);
                     }
                     if(!this.targetOre.mayMine(Miner(unit)))
                     {
                        unit.walk(xWalking / 20,(this.targetOre.y + yOffset - unit.py) / 20,Util.sgn(this.targetOre.x - unit.x));
                     }
                     else
                     {
                        Miner(unit).mine();
                        this.targetOre.startMining(Miner(unit));
                     }
                  }
               }
            }
         }
         else if(mayMoveToAttack && unit.sqrDistanceTo(target) < 150000)
         {
            yMovement = 0;
            if(target.type != Unit.U_WALL && Math.abs(unit.px - target.px) < 200)
            {
               if(Math.abs(unit.py - target.py) < 40)
               {
                  yMovement = 0;
               }
               else
               {
                  yMovement = target.py - unit.py;
               }
            }
            if(Util.sgn(target.dx) == Util.sgn(unit.dx) && Math.abs(target.dx) > 1)
            {
               unit.walk((target.px - unit.px) / 20,yMovement,Util.sgn(target.px - unit.px));
            }
            else
            {
               offset = Util.sgn(target.px - unit.px) * unit.weaponReach() * 0.5;
               if(Math.abs(target.px - unit.px) < unit.weaponReach() * 0.9)
               {
                  unit.walk(0,yMovement,Util.sgn(target.px - unit.px));
               }
               else
               {
                  unit.walk((target.px - offset - unit.px) / 100,yMovement,Util.sgn(target.px - unit.px));
               }
            }
            if(Math.abs(target.px - unit.px - (unit.pwidth + target.pwidth) * 0.125 * unit.team.direction) < 10)
            {
               unit.faceDirection(target.px - unit.px);
            }
         }
         else if(mayMove)
         {
            unit.mayWalkThrough = false;
            unit.walk((goalX - unit.px) / 20,(goalY - unit.py) / 20,intendedX);
         }
         this.updateAutoMiner(Miner(unit),game);
      }
      
      protected function updateAutoMiner(miner:Miner, game:StickWar) : void
      {
         if(this.isUnassigned)
         {
            return;
         }
         if(this.isGoingForOre)
         {
            if(MinerAi(miner.ai).targetOre == null || Boolean(MinerAi(miner.ai).targetOre) && Boolean(!MinerAi(miner.ai).targetOre.hasMiningSpot(miner)))
            {
               this.iterateOverFreeMines(miner,game);
            }
         }
         else if(MinerAi(miner.ai).targetOre == null || Boolean(MinerAi(miner.ai).targetOre) && Boolean(!MinerAi(miner.ai).targetOre.hasMiningSpot(miner)))
         {
            miner.team.statue.reserveMiningSpot(miner);
            MinerAi(miner.ai).targetOre = miner.team.statue;
         }
      }
      
      protected function iterateOverFreeMines(miner:Miner, game:StickWar) : void
      {
         var i:int = 0;
         var gold:Ore = null;
         if(unit.team.direction == 1)
         {
            for(i = 0; i < game.map.gold.length / 2; i++)
            {
               gold = game.map.gold[i];
               if(this.getFreeMine(miner,game,gold))
               {
                  break;
               }
            }
         }
         else
         {
            for(i = game.map.gold.length - 1; i >= game.map.gold.length / 2; i--)
            {
               gold = game.map.gold[i];
               if(this.getFreeMine(miner,game,gold))
               {
                  break;
               }
            }
         }
      }
      
      protected function getFreeMine(miner:Miner, game:StickWar, gold:Ore) : Boolean
      {
         if(!gold.isMineFull())
         {
            gold.reserveMiningSpot(miner);
            MinerAi(miner.ai).targetOre = gold;
            return true;
         }
         return false;
      }
      
      public function get targetOre() : Ore
      {
         return this._targetOre;
      }
      
      public function set targetOre(value:Ore) : void
      {
         if(this._targetOre == value)
         {
            return;
         }
         if(Boolean(this._targetOre))
         {
            this._targetOre.stopMining(Miner(unit));
            this._targetOre.releaseMiningSpot(Miner(unit));
         }
         this._targetOre = value;
      }
      
      override public function cleanUp() : void
      {
         this.targetOre = null;
      }
      
      public function get isGoingForOre() : Boolean
      {
         return this._isGoingForOre;
      }
      
      public function set isGoingForOre(value:Boolean) : void
      {
         this._isGoingForOre = value;
      }
      
      public function get isUnassigned() : Boolean
      {
         return this._isUnassigned;
      }
      
      public function set isUnassigned(value:Boolean) : void
      {
         this._isUnassigned = value;
      }
   }
}

